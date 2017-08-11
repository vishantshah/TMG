/**
* @author Unknown
* @date Unknown
* @description Test class for SubscriptionCallCentreRenewalController - Offline Renewal page
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         25/02/2015  //together with Start_Date__c validation coverage I added some extra methods to increase coverage in general
Wiktor Czykin   1.2         29/04/2015  //removed coverage for Start_Date__c validations
Cristina Anghenie1.3        08/09/2015  //test subs start date when paying by cheque
Wiktor Czykin   1.4         14/10/2015  //modified testCorrectDatesSentToMPP(),testCorrectSubStartDateForCheque(), testOfferRenewalWithPreviousSub(),testGuidChanges()
Wiktor Czykin   1.5         02/11/2015  //added coverage for email duplicate failure
Wiktor Czykin   1.6         17/02/2016  //modified testEditSaveCancelAccount()
Wiktor Czykin   1.7         24/02/2016  //modified testGuidChanges()
Wiktor Czykin   1.8         13/04/2016  //modified testBooleans() and testDoNotContactFunctionality()
Gavin Palmer    1.9         16/06/2016  //various modifications in line with the refactoring and modification of SubscriptionCallCentreRenewalController
Wiktor Czykin   2.0         01/11/2016  //added testProductSwitchMethodsIncentivesCheck()
Pawel Chrzanowski   2.1     07/11/2016  //modified testSearchAccountAndSubscription() and testupsertSubscriptionIncentive()
Pawel Chrzanowski   2.2     18/11/2016  //modified testSuccessfulTakePayment()
Wiktor Czykin   2.3         18/01/2017  //fixed failing assertion in testSuccessfulTakePayment()
Wiktor Czykin   2.4         31/01/2017  //modified testupsertSubscriptionIncentive()
Wiktor Czykin   2.5         21/03/2017  //modified to work with email uniqueness check
Pawel Chrzanowski   2.6     03/05/2017  //removed unused Marketing Preferences
**/
@isTest
private class SubscriptionCallCentreRenewalControlTest {

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.1
    Function - not covered getters check
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         08/09/2016  //removed no longer existing methods checks
    ****************************************************************************************/
    private static testMethod void testFewGettersSetters(){
        Test.startTest();
            SubscriptionCallCentreRenewalController controller = new SubscriptionCallCentreRenewalController();
            System.assertEquals(2, controller.OrderMethodValues.size());

            controller.selectedDelivery = Constants.DELIVERYTYPE_HND;
            System.assertEquals(Constants.DELIVERYTYPE_HND, controller.selectedDelivery);
            System.assert(controller.displayRetailers);
            //set empty account to check that Id == null in lastUpdateDate getter
            controller.accountDetail = new Account();
            System.assertEquals(null, controller.lastUpdateDate);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - edit context load for account - failure
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountEditContextLoadFailure(){
        Test.startTest();
            SubscriptionCallCentreRenewalController controller = new SubscriptionCallCentreRenewalController();
            controller.editAccount();
        Test.stopTest();
        System.assert(ApexPages.hasMessages());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - edit context load for subscription - failure
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSubscriptionEditContextLoadFailure(){
        Test.startTest();
            SubscriptionCallCentreRenewalController controller = new SubscriptionCallCentreRenewalController();
            controller.editSub();
            System.assert(ApexPages.hasMessages());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - success account update
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveAccountPositive(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.createSubscriptions();
        Test.startTest();
            SubscriptionCallCentreRenewalController controller = new SubscriptionCallCentreRenewalController();
            controller.accountDetail = td.lstIndividualSubscribers[0];
            controller.accountDetail.PersonMailingStreet = 'some street';
            controller.accountDetail.PersonMailingCity = 'London';
            controller.accountDetail.PersonMailingPostalCode = 'EH1 1JG';
            controller.saveAccount();
        Test.stopTest();
        System.assert(!ApexPages.hasMessages());
        System.assert(!controller.getAccountDetailsFound());
    }

    /***************************************************************************************
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - test save perms functionality
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         14/10/2015  //clean up code and increase code coverage
    ****************************************************************************************/
    private static testMethod void testSavePermsFunctionality(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createIndividualSubscribers();
        SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
        ctl.accountDetail = new Account();
        Test.startTest();
            try{
                ctl.savePerms();
            }catch(DMLException ex){
                System.assert(ApexPages.hasMessages());
            }
            ctl.accountdetail = tdu.lstIndividualSubscribers[0];
            try{
                ctl.savePerms();
            }catch(DMLException ex){
                System.assert(!ApexPages.hasMessages());
            }
        Test.stopTest();
        System.assertEquals(System.Today(),ctl.accountdetail.Permissions_Last_Change_Date__c);
        System.assertEquals(tdu.lstIndividualSubscribers[0].Id,ctl.accountId);
    }

    /***************************************************************************************
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - Marketing perms properties start
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         14/10/2015  //clean up code and increase code coverage
    Pawel Chrzanowski   1.2         03/05/2017  //removed unused Marketing Preferences
    ****************************************************************************************/
    private static testMethod void testMarketingperms() {
        SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
        ctl.accountDetail = new Account(Name='testing');
        Boolean p = ctl.p2ndEmail;
        p = ctl.p2ndPhone;
        p = ctl.p2ndPost;
        p = ctl.p2ndSMS;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - unknown
    Version - 1.0
    Function - test globalAccountSearch negatives
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         14/10/2015  //clean up code and increase code coverage
    ****************************************************************************************/
    private static testMethod void testGlobalAccountSearchNegatives(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createSubscriptions();
        tdu.lstIndividualSubscribers[0].LastName = 'TMG Last';
        tdu.lstIndividualSubscribers[0].PersonMailingPostalCode = 'E11 1JY';
        update tdu.lstIndividualSubscribers[0];
        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            ctl.Surname = null;
            ctl.PostCode = null;
            ctl.TsNumber = null;
            ctl.globalAccountSearch();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please enter a search criteria.'));
            ctl.Surname = 'TMG Last';
            ctl.PostCode = null;
            ctl.TsNumber = null;
            ctl.globalAccountSearch();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Subscriber_search_last_name_and_post_code_mandatory));
            ctl.Surname = null;
            ctl.PostCode = 'E11 1JY';
            ctl.TsNumber = null;
            ctl.globalAccountSearch();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Subscriber_search_last_name_and_post_code_mandatory));
            ctl.Surname = 'TMG Last';
            ctl.PostCode = 'E11 1JY';
            ctl.globalAccountSearch();
        Test.stopTest();
        System.assertEquals(1,ctl.foundAccounts.size());
        System.assertEquals(0,ctl.foundSubscriptions.size());
        System.assertEquals(null,ctl.accountId);
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - 14/10/2015
    Version - 1.1
    Function - test search account and its subscriptions
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         08/09/2016  //replaced removed methods calls
    Pawel Chrzanowski   1.2         07/11/2016  //fixed incentives
    ****************************************************************************************/
    private static testMethod void testSearchAccountAndSubscription(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createRetailers();

        tdu.createSubscriptionIncentiveAssociation();
        tdu.lstIncentives[0].Is_Valid_For_Renewal__c = true;
        update tdu.lstIncentives[0];

        tdu.createTCodeManagement();

        tdu.lstIndividualSubscribers[0].LastName = 'TMG Last';
        tdu.lstIndividualSubscribers[0].PersonMailingPostalCode = 'E11 1JY';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_DD;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstRetailers[0].Id,Date.newInstance(2015,07,06), tdu.lstZproducts[0].Id);
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.isContinuous__c = true;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Delivery_Type__c = 'HND';
        subOffered.TCode__c = tdu.lstTCodeManagement[0].Id;
        insert subOffered;

        tdu.lstIncentivesAssociation[0].Reason__c = 'Good Will';
        tdu.lstIncentivesAssociation[0].Subscription__c = subOffered.Id;
        update tdu.lstIncentivesAssociation[0];

        tdu.createTCodeProducts();
        tdu.createTCodeProductIncentives();

        subOffered = [SELECT Id, MPP_Scheduled_First_Payment_Date__c, Start_Date__c,if_Is_Renewal_Binary__c,Delivery_Type__c FROM Subscription__c WHERE Previous_Subscription__c =: tdu.lstSubscriptions[0].Id];
        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            ctl.getIncentiveDescription();
            ctl.Surname = 'TMG Last';
            ctl.PostCode = 'E11 1JY';
            ctl.globalAccountSearch();
            System.assertEquals(false,ctl.getAccountDetailsFound());
            System.assertEquals(1,ctl.foundAccounts.size());
            System.assertEquals(true,ctl.displaySearchButton);
            ctl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctl.searchAccount();
            System.assertEquals(365,ctl.ChequePaymentLength);
            System.assertEquals(null,ctl.chequeBatchSelected);
            System.assertEquals(false,ctl.getAccEditEnabled());
            System.assertEquals(false,ctl.getSubEditEnabled());
            System.assertEquals(1,ctl.foundSubscriptions.size());
            System.assert(ctl.showPermissions);
            ctl.selectedDelivery=Constants.DELIVERYTYPE_HND;
            System.assertEquals(Constants.DELIVERYTYPE_HND, ctl.selectedDelivery);
            System.assertEquals(true,ctl.displayRetailers);

            ctl.subId = subOffered.Id;
            ctl.searchSub();
            System.assertEquals(Constants.DELIVERYTYPE_HND, ctl.foundSubscriptions[0].Delivery_Type__c);
            System.assertEquals('Inbound',ctl.SelectedOrderMethod);
            System.assertEquals('15',ctl.PreferedStartPaymentDate);
            System.assertEquals(Constants.SUB_PMETHOD_DD,ctl.DisplayedPaymentType);
            System.assertEquals('continuous',ctl.subscriptionType);
            System.assertEquals('Quarterly',ctl.PaymentFrequency);
            System.assertEquals(false,ctl.displayRetailerResults);
            System.assertEquals(false,ctl.displaySelectedRetailerMsg);
            System.assertEquals(tdu.lstRetailers[0].Id,ctl.newselectedRetailer);
            System.assertEquals(null,ctl.selectedRetailer);
            System.assertEquals('Good Will',ctl.selectedIncentiveReason);
            System.assertEquals(null,ctl.chequeBatchSelected);
            System.assertEquals(false,ctl.getSubEditEnabled());
            tdu.createCheques();
            ctl.cheque = tdu.lstCheques[0];
            ctl.chequeBatchSelected = tdu.lstChequeBatches[0].Name;
            ctl.editSub();
            ctl.foundSubscriptions[0].Delivery_Type__c = 'OTC';
            System.assertEquals(true,ctl.subEditEnabled);
            System.assertNotEquals(null,ctl.chequeBeforeEdit);
            System.assertEquals(false,ctl.displayRetailerResults);
            System.assertEquals(tdu.lstChequeBatches[0].Name,ctl.chequeBatchBeforeEdit);
            System.assertEquals(tdu.lstIncentivesAssociation[0].Incentive__c, ctl.selectedIncentiveBeforeEdit);
            System.assertEquals('Good Will',ctl.SelectedIncentiveReasonBeforeEdit);
            System.assertEquals('HND', ctl.selectedDelivery);
            System.assertEquals('HND',ctl.selectedDeliveryBeforeEdit);
            System.assertEquals('Inbound',ctl.OrderMethodBeforeEdit);
            ctl.cancelSubEdit();
            System.assertEquals('HND', ctl.selectedDelivery);
            System.assertEquals(tdu.lstChequeBatches[0].Name,ctl.chequeBatchSelected);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - 14/10/2015
    Version - 1.1
    Function - test edit/save/cancel account
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         17/02/2016 //fix for assertion
    ****************************************************************************************/
    private static testMethod void testEditSaveCancelAccount(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.loadCountryCodes();
        tdu.createSubscriptions();
        tdu.lstIndividualSubscribers[0].LastName = 'TMG Last';
        tdu.lstIndividualSubscribers[0].PersonMailingPostalCode = 'E11 1JY';
        update tdu.lstIndividualSubscribers[0];
        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            ctl.getCountries();
            ctl.Surname = 'TMG Last';
            ctl.PostCode = 'E11 1JY';
            ctl.globalAccountSearch();
            ctl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctl.searchAccount();
            ctl.editAccount();
            System.assertEquals(true,ctl.getAccEditEnabled());
            ctl.fetchAccountDetails();
            ctl.getAccountDetail();
            ctl.subBeforeEdit = tdu.lstSubscriptions[0];
            ctl.accountDetail.PersonMailingStreet = 'TMG Street';
            ctl.cancelAccountEdit();
            System.assertEquals(false,ctl.accEditEnabled);
            tdu.lstIndividualSubscribers[0] = [SELECT Id, FirstName, PersonMailingStreet,PersonMailingCity FROM Account WHERE Id =:tdu.lstIndividualSubscribers[0].Id];
            System.assertNotEquals('TMG Street',tdu.lstIndividualSubscribers[0].PersonMailingStreet);
            ctl.editAccount();
            ctl.accountDetail.FirstName = 'TMG First';
            ctl.accountDetail.PersonMailingCity = null;
            ctl.accountDetail.PersonMailingCountry = null;
            ctl.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'First Name, Last Name, Mailing Street, Mailing City, Postal Code are mandatory!'));
            ctl.accountDetail.PersonMailingStreet = 'TMG Street';
            ctl.accountDetail.PersonMailingCity = 'TMG City';
            ctl.accountDetail.PersonMailingCountry = 'GB';
            ctl.saveAccount();
            System.assertEquals('United Kingdom',ctl.getCountryName());
            tdu.lstIndividualSubscribers[0] = [SELECT Id, FirstName, PersonMailingStreet,PersonMailingCity FROM Account WHERE Id =:tdu.lstIndividualSubscribers[0].Id];
            System.assertEquals('TMG First',tdu.lstIndividualSubscribers[0].FirstName);
            System.assertEquals('TMG Street',tdu.lstIndividualSubscribers[0].PersonMailingStreet);
            System.assertEquals('TMG City',tdu.lstIndividualSubscribers[0].PersonMailingCity);
            try{
                ctl.accountDetail = new Account();
                ctl.accountDetail.FirstName = '123';
                ctl.accountDetail.PersonMailingStreet = '1212';
                ctl.accountDetail.PersonMailingCity = '21321';
                ctl.accountDetail.PersonMailingCountry = '31231';
                ctl.saveAccount();
            }catch(system.DMLException dmlex){
                System.assert(ApexPages.hasMessages());
            }
        Test.stoptest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - 14/10/2015
    Version - 1.1
    Function - test edit/save/cancel subscription
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         08/09/2016  //replaced removed method call
    ****************************************************************************************/
    private static testMethod void testEditSaveCancelSubscription(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createSubscriptions();
        tdu.lstIndividualSubscribers[0].LastName = 'TMG Last';
        tdu.lstIndividualSubscribers[0].PersonMailingPostalCode = 'E11 1JY';
        update tdu.lstIndividualSubscribers[0];

        tdu.createSubscriptionIncentiveAssociation();

        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            ctl.getSubDetail();
            ctl.subscriptionDetail = tdu.lstSubscriptions[0];
            ctl.editSub();
            ctl.subscriptionDetail.Start_Date__c = System.Today();
            ctl.cancelSubEdit();
            Subscription__c sub = [SELECT Start_Date__c FROM Subscription__c WHERE Id =: tdu.lstSubscriptions[0].Id];
            System.assertNotEquals(System.today(),sub.Start_Date__c);
            System.assertEquals(false,ctl.subEditEnabled);
            ctl.editSub();
            ctl.subscriptionDetail.Payment_Type__c = Constants.SUB_PMETHOD_CC;
            ctl.subscriptionDetail.isContinuous__c = true;
            ctl.saveSub();
            System.assertEquals(Constants.DD_COL_FREQ_MONTHLY,ctl.subscriptionDetail.MPP_CC_Frequency__c);
            ctl.editSub();
            ctl.subscriptionDetail.Payment_Type__c = Constants.SUB_ACQUISITION_PAYMENT_DD;
            ctl.subscriptionDetail.isContinuous__c = false;
            ctl.saveSub();
            System.assertEquals(null,ctl.subscriptionDetail.MPP_CC_Frequency__c);
            ctl.editSub();
            ctl.preferedStartPaymentDate = '15';
            ctl.displayedPaymentType = Constants.SUB_PMETHOD_DD;
            ctl.saveSub();
            ctl.displayedPaymentType = 'cheque';
            ctl.createNewBatch = false;
            ctl.chequeBatchSelected = null;
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'You must select an existing cheque batch, if not creating a new one.'));

            ctl.createNewBatch = true;
            ctl.cheque = new Cheque__c();
            ctl.cheque.Name_on_Cheque__c = '';
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Cheque_name_blank));
            ctl.cheque.Name_on_Cheque__c = 'test';
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Cheque_account_number_blank));
            ctl.cheque.Account_Number__c = '22222222';
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Sort_code_empty));
            ctl.cheque.Sort_Code__c = '000000';
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Cheque_reference_number_blank));
            ctl.cheque.Ref_Number_on_Cheque__c = 'testRef';
            ctl.SelectedIncentive = tdu.lstIncentives[0].Id;
            ctl.SelectedIncentiveReason = null;
            System.assertEquals(false,ctl.validSelectedIncentive());
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Incentive_reason_required_if_incentive_is_selected));
            ctl.SelectedIncentiveReason = 'good will';
            System.assert(ctl.validSelectedIncentive());
            ctl.selectedOrderMethod = null;
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Order_method_is_required));
            ctl.selectedOrderMethod = 'Coupon';
            ctl.toggleIsContinuous();
            System.assertEquals(false,ctl.subscriptionDetail.isContinuous__c);
            ctl.preferedStartPaymentDate = '15';
            ctl.displayedPaymentType = Constants.SUB_PMETHOD_DD;
            ctl.selectedDelivery = Constants.DELIVERYTYPE_OTC;
            ctl.saveSub();
            System.assertEquals('Coupon',ctl.subscriptionDetail.Order_Taken_Method__c);
        Test.stoptest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - 14/10/2015
    Version - 1.0
    Function - test edit/save/cancel subscription
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testValidateContinuousFlagLogicNegatives(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createSubscriptions();
        tdu.lstSubscriptions[0].Subscription_Duration_Picklist__c = null;
        update tdu.lstSubscriptions[0];

        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            System.assert(!ctl.validateContinuousFlagLogic(tdu.lstSubscriptions[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please select a duration.'));
            tdu.lstSubscriptions[0].Subscription_Duration_Picklist__c = '52';
            tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_DD;
            tdu.lstSubscriptions[0].IsContinuous__c = false;
            System.assert(!ctl.validateContinuousFlagLogic(tdu.lstSubscriptions[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please select isContinuous.'));
            tdu.lstSubscriptions[0].Subscription_Duration_Picklist__c = '26';
            tdu.lstSubscriptions[0].IsContinuous__c = true;
            System.assert(!ctl.validateContinuousFlagLogic(tdu.lstSubscriptions[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Renewal_Continuous_subscriptions_have_to_be_52_weeks));
            tdu.lstSubscriptions[0].Subscription_Duration_Picklist__c = '26';
            tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
            tdu.lstSubscriptions[0].IsContinuous__c = true;
            System.assert(!ctl.validateContinuousFlagLogic(tdu.lstSubscriptions[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Renewal_Continuous_subscriptions_have_to_be_52_weeks));
            tdu.lstSubscriptions[0].Payment_Type__c = 'Cheque';
            tdu.lstSubscriptions[0].IsContinuous__c = true;
            System.assert(!ctl.validateContinuousFlagLogic(tdu.lstSubscriptions[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Continuous should be checked only for Direct Debit and Credit Card 52 weeks.'));
            tdu.lstSubscriptions[0].Subscription_Duration_Picklist__c = '52';
            tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_DD;
            tdu.lstSubscriptions[0].IsContinuous__c = true;
            System.assert(ctl.validateContinuousFlagLogic(tdu.lstSubscriptions[0]));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - unknown
    Version - 1.0
    Function - test Retailers Functionality
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         15/10/2015  //clean up code and increase code coverage
    ***************************************************************************************/
    private static testMethod void testRetailersFunctionality(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createRetailers();
        tdu.lstRetailers[0].BillingPostalCode = 'E11 1JY';
        tdu.lstRetailers[0].Retailer_Active_Sub_Count__c = 2;
        tdu.lstRetailers[0].RET_ID__c = '123456';
        update tdu.lstRetailers[0];
        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            try{
                ctl.retrieveAllRetailers();
            }catch(Exception e){
                System.assert(APexPages.hasMessages());
            }
            ctl.postcodeRetailSearch = 'E11 1JY';
            ctl.retrieveAllRetailers();
            System.AssertEquals(true,ctl.displayRetailers);
            System.AssertEquals(1, ctl.allActiveRetailers.size());
            System.AssertEquals(true,ctl.displayRetailerResults);
            ctl.retailerID = '123456';
            ctl.retailerAccount = null;
            ctl.selectRetailerByID();
            System.AssertNotEquals(null,ctl.retailerAccount);
            System.AssertEquals(true,ctl.displaySelectedRetailerMsg);
            System.AssertEquals(true,ctl.displayRetailerResults);
            ctl.selectRetailer();
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - unknown
    Date - unknown
    Version - 1.2
    Function - test booleans
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         14/10/2015  //clean up code and increase code coverage
    Wiktor Czykin       1.2         13/04/2016  //removed assertion for removed variable and changed
    Pawel Chrzanowski   1.3         03/05/2017  //removed unused Marketing Preferences
    ****************************************************************************************/
    private static testmethod void testBooleans(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createIndividualSubscribers();
        Test.startTest();
            SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
            ctl.accountdetail = tdu.lstIndividualSubscribers[0];
            System.AssertEquals(false,ctl.p2ndemail);
            System.AssertEquals(false,ctl.p2ndphone);
            System.AssertEquals(false,ctl.p2ndpost);
            System.AssertEquals(false,ctl.p2ndSMS);
            System.Assert(!ctl.getSubEditEnabled());
            ctl.saveAccount();
       Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 21/07/2015
    Version - 1.1
    Function - test guid changes
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/10/2015  //added retailer to subscription creation
    Wiktor Czykin   1.2         24/02/2016  //changed the way account is created
    ****************************************************************************************/
    private static testmethod void testGuidChanges(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createRetailers();
        tdu.createIndividualSubscribers();
        tdu.createTCodeManagement();

        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        tdu.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        update tdu.lstTCodeManagement[0];

        Account premiumAcc = tdu.lstIndividualSubscribers[0];

        Subscription__c subscription = TestDataUtility.newSubscripiton(1, premiumAcc.Id, tdu.lstRetailers[0].Id, null);
        subscription.Subscription_Status__c = 'Active';
        insert subscription;

        String guid = [SELECT Id, Guid__c FROM Account WHERE Id =: premiumAcc.Id limit 1].Guid__c;
        SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
        ctl.accountDetail = premiumAcc;
        ctl.subscriptionDetail = subscription;
        Test.startTest();
            ctl.saveAndTakePayment();
            premiumAcc = [SELECT Id, Guid__c FROM Account WHERE Id =: premiumAcc.Id];
        Test.stopTest();
        //make sure guid doesnt get blanked out after taking payment
        System.assertEquals(guid,premiumAcc.Guid__c);
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 13/08/2015
    Version - 1.1
    Function - test guid changes
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/10/2015  //added retailer for subscription creation
    ****************************************************************************************/
    private static testmethod void testCorrectDatesSentToMPP(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createSubscriptionIncentiveAssociation();
        tdu.createTCodeManagement();

        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        tdu.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        update tdu.lstTCodeManagement[0];

        tdu.lstIndividualSubscribers[0].Firstname = 'Test';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstRetailers[0].Id, Date.newInstance(2015,07,06), tdu.lstZproducts[0].Id);
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.isContinuous__c = true;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.TCode__c = tdu.lstTCodeManagement[0].Id;
        insert subOffered;

        subOffered = [SELECT Id, MPP_Scheduled_First_Payment_Date__c, Start_Date__c,if_Is_Renewal_Binary__c FROM Subscription__c WHERE Previous_Subscription__c =: tdu.lstSubscriptions[0].Id];
        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        ctrl.accountDetail = tdu.lstIndividualSubscribers[0];
        ctrl.subscriptionDetail = subOffered;
        Test.startTest();
            ctrl.TsNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctrl.globalAccountSearch();
            ctrl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctrl.searchAccount();
            ctrl.subId = subOffered.Id;
            ctrl.searchSub();
            System.assertEquals(null, ctrl.saveAndTakePayment());

            subOffered.PaymentDate__c = '1';
            update subOffered;
            ctrl.TsNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.globalAccountSearch();
            ctrl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctrl.searchAccount();
            ctrl.subId = subOffered.Id;
            ctrl.searchSub();
            System.assertEquals(null, ctrl.saveAndTakePayment());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 04/09/2015
    Version - 1.0
    Function - test if you can get the sub info for an offer sub that doesnt have a previous sub linked to it
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testmethod void testOfferRenewalWithoutPreviousSub(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createSubscriptions();

        tdu.lstIndividualSubscribers[0].Firstname = 'Test';
        update tdu.lstIndividualSubscribers[0];

        Test.startTest();
            SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
            ctrl.TSNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.globalAccountSearch();
            System.assertEquals(false,ctrl.displaySearchButton);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 04/09/2015
    Version - 1.1
    Function - test if you can get the sub info for an offer sub that has a previous sub linked to it
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/10/2015  //added retailer for subscription creation
    ****************************************************************************************/
    private static testmethod void testOfferRenewalWithPreviousSub(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createSubscriptions();
        tdu.createTCodeManagement();

        tdu.lstIndividualSubscribers[0].Firstname = 'Test';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstRetailers[0].Id,Date.newInstance(2015,07,06), tdu.lstZproducts[0].Id);
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.isContinuous__c = true;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.TCode__c = tdu.lstTCodeManagement[0].Id;
        insert subOffered;
        Test.startTest();
            SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
            ctrl.TSNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.globalAccountSearch();
            System.assertEquals(true,ctrl.displaySearchButton);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 16/10/2015
    Version - 1.1
    Function - test subscription date when payment type is cheque negatives
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testmethod void testCorrectSubStartDateForChequeNegatives(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.loadGeneral();
        tdu.createSubscriptions();
        tdu.createSubscriptionIncentiveAssociation();
        tdu.createTCodeManagement();

        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        tdu.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        update tdu.lstTCodeManagement[0];

        tdu.lstIndividualSubscribers[0].Firstname = 'Test';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstRetailers[0].Id,System.Today(), tdu.lstZproducts[0].Id);
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.isContinuous__c = true;
        subOffered.PaymentDate__c = '1';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Payment_Type__c = 'Cheque';
        subOffered.TCode__c = tdu.lstTCodeManagement[0].Id;
        insert subOffered;

        subOffered = [SELECT Id, MPP_Scheduled_First_Payment_Date__c, Start_Date__c,if_Is_Renewal_Binary__c FROM Subscription__c WHERE Previous_Subscription__c =: tdu.lstSubscriptions[0].Id];
        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        ctrl.accountDetail = tdu.lstIndividualSubscribers[0];
        ctrl.subscriptionDetail = subOffered;
        Test.startTest();
            ctrl.TsNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.globalAccountSearch();
            ctrl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctrl.searchAccount();
            ctrl.subId = subOffered.Id;
            ctrl.searchSub();
            ctrl.createNewBatch = true;
            ctrl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Cheque_name_blank));
            ctrl.cheque.Name_on_Cheque__c = 'test';
            ctrl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Cheque_account_number_blank));
            ctrl.cheque.Account_Number__c = '22222222';
            ctrl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Sort_code_empty));
            ctrl.cheque.Sort_Code__c = '000000';
            ctrl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Cheque_reference_number_blank));
            ctrl.cheque.Ref_Number_on_Cheque__c = 'testRef';
            ctrl.SelectedIncentive = tdu.lstIncentives[0].Id;
            ctrl.SelectedIncentiveReason = null;
            ctrl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Incentive_reason_required_if_incentive_is_selected));
            ctrl.SelectedIncentiveReason = 'good will';
            ctrl.selectedOrderMethod = null;
            ctrl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Offline_Renewal_Order_method_is_required));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 07/09/2015
    Version - 1.1
    Function - test subscription date when payment type is cheque
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/10/2015  //added retailer for subscription creation
    ****************************************************************************************/
    private static testmethod void testCorrectSubStartDateForCheque(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();
        tdu.createSubscriptionIncentiveAssociation();
        tdu.createTCodeManagement();

        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        tdu.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        update tdu.lstTCodeManagement[0];

        tdu.lstIndividualSubscribers[0].Firstname = 'Test';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstRetailers[0].Id,System.Today(), tdu.lstZproducts[0].Id);
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.Start_Date__c = Date.newInstance(2014,07,07);
        subOffered.isContinuous__c = true;
        subOffered.PaymentDate__c = '1';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Payment_Type__c = Constants.SUB_PMETHOD_CHEQUE;
        subOffered.TCode__c = tdu.lstTCodeManagement[0].Id;
        insert subOffered;

        subOffered = [SELECT Id, MPP_Scheduled_First_Payment_Date__c, Start_Date__c,if_Is_Renewal_Binary__c FROM Subscription__c WHERE Previous_Subscription__c =: tdu.lstSubscriptions[0].Id];
        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        ctrl.accountDetail = tdu.lstIndividualSubscribers[0];
        ctrl.subscriptionDetail = subOffered;
        Test.startTest();
            ctrl.TsNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.globalAccountSearch();
            ctrl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctrl.searchAccount();
            ctrl.subId = subOffered.Id;
            ctrl.searchSub();
            Id chequeBatchId = TMGUtil.createChequeBatch();
            System.assertNotEquals(null, chequeBatchId);
            List<Cheque_Batch__c> cb = [select Name from Cheque_Batch__c where Id =:chequeBatchId];
            System.assert(!cb.isEmpty());
            ctrl.chequeBatchSelected = cb[0].Name;
            ctrl.createNewBatch = false;
            ctrl.cheque.Name_on_Cheque__c = 'test';
            ctrl.cheque.Account_Number__c = '22222222';
            ctrl.cheque.Sort_Code__c = '000000';
            ctrl.cheque.Ref_Number_on_Cheque__c = 'testRef';
            ctrl.selectedOrderMethod = 'Coupon';
            ctrl.saveSub();
            ctrl.saveAndTakePayment();
            System.assertEquals(Constants.SUB_PMETHOD_CHEQUE, ctrl.DisplayedPaymentType);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 26/10/2015
    Version - 1.1
    Function - test subscription start date when payment type is cheque and the subs start date is in the future
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testmethod void testCorrectSubStartDateForChequeWhenDateInFuture(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createSubscriptions();
        tdu.createSubscriptionIncentiveAssociation();
        tdu.createTCodeManagement();

        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        tdu.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        update tdu.lstTCodeManagement[0];

        tdu.lstIndividualSubscribers[0].Firstname = 'Test';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstRetailers[0].Id,System.Today(), tdu.lstZproducts[0].Id);
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.Start_Date__c = System.today().addDays(3);
        subOffered.isContinuous__c = true;
        subOffered.PaymentDate__c = '1';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Payment_Type__c = 'Cheque';
        subOffered.TCode__c = tdu.lstTCodeManagement[0].Id;
        insert subOffered;

        subOffered = [SELECT Id, MPP_Scheduled_First_Payment_Date__c, Start_Date__c,if_Is_Renewal_Binary__c FROM Subscription__c WHERE Previous_Subscription__c =: tdu.lstSubscriptions[0].Id];
        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        ctrl.accountDetail = tdu.lstIndividualSubscribers[0];
        ctrl.subscriptionDetail = subOffered;
        Test.startTest();
            ctrl.TsNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id=: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
            ctrl.globalAccountSearch();
            ctrl.accountId = tdu.lstIndividualSubscribers[0].Id;
            ctrl.searchAccount();
            ctrl.subId = subOffered.Id;
            ctrl.searchSub();
            ctrl.createNewBatch = false;
            ctrl.cheque.Name_on_Cheque__c = 'test';
            ctrl.cheque.Account_Number__c = '22222222';
            ctrl.cheque.Sort_Code__c = '000000';
            ctrl.cheque.Ref_Number_on_Cheque__c = 'testRef';
            ctrl.selectedOrderMethod = 'Coupon';
            ctrl.saveSub();
            ctrl.saveAndTakePayment();
            System.assertEquals('Cheque',ctrl.DisplayedPaymentType);
            subOffered = [SELECT Id, Start_Date__c,if_Is_Renewal_Binary__c FROM Subscription__c WHERE Id =: subOffered.Id];
        Test.stopTest();
        System.assertEquals(System.today().addDays(3),subOffered.Start_Date__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/11/2015
    Version - 1.0
    Function - email duplicate failure on account update
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void testAccountEmailDuplicateOnSaveFailure(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();
        td.lstIndividualSubscribers[0].PersonMailingStreet = 'Buckingham Palace Road';
        td.lstIndividualSubscribers[0].PersonMailingCity = 'London';
        td.lstIndividualSubscribers[1].PersonEmail = td.lstIndividualSubscribers[0].PersonEmail;
        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        Test.startTest();
            ctrl.accountDetail = td.lstIndividualSubscribers[1];
            ctrl.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Renewal_Email_duplicate_error));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/11/2015
    Version - 1.0
    Function - email duplicate failure on saveAndTakePayment
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountEmailDuplicateOnSaveAndTakePaymentFailure(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();
        td.lstIndividualSubscribers[1].PersonEmail = td.lstIndividualSubscribers[0].PersonEmail;
        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        Test.startTest();
            ctrl.accountDetail = td.lstIndividualSubscribers[1];
            PageReference pr = ctrl.saveAndTakePayment();
            System.assertEquals(null, pr);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Renewal_Email_duplicate_error), ApexPages.getMessages());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 16/06/2016
    Version - 1.0
    Function - testing email iFrame methods
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testEmailIFrameMethods(){
        TestDataUtility td = new TestDataUtility(2);
        td.createIndividualSubscribers();

        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        System.assertEquals(false, ctrl.showEmailIFrame);
        Test.startTest();
            ctrl.displayChangeEmailIFrame();
            System.assertEquals(true, ctrl.showEmailIFrame);

            ctrl.hideChangeEmailIFrame();
            System.assertEquals(false, ctrl.showEmailIFrame);

            ctrl.displayChangeEmailIFrame();

            ctrl.accountDetail = new Account();
            ctrl.refetchSubscriberEmail();
        Test.stopTest();

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Account_refetch_error_update),
            'Account found where there should not be one');
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 16/06/2016
    Version - 1.0
    Function - testing product switch methods
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testProductSwitchMethods(){
        TestDataUtility td = new TestDataUtility(2);
        td.createSubscriptions();
        td.createTCodeProducts();

        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        Test.startTest();
            ctrl.subscriptionDetail = td.lstSubscriptions[0];
            ctrl.subscriptionDetail.TCode__c = td.lstTCodeManagement[0].Id;
            ctrl.accountDetail = td.lstIndividualSubscribers[0];
            ctrl.changeProductId(td.lstZproducts[0].Id);
            System.assertEquals(td.lstTCodeProducts[0].Weekly_Price__c, ctrl.subscriptionDetail.Weekly_Price__c);

            TCodeProductWrapper tcp = new TCodeProductWrapper(td.lstTCodeProducts[0]);
            ctrl.prepareProductListBeforeView(new List<TCodeProductWrapper>{tcp});

        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 01/11/2016
    Version - 1.0
    Function - testing product switch methods - incentives switch impact
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testProductSwitchMethodsIncentivesCheck(){
        TestDataUtility td = new TestDataUtility(2);
        td.createSubscriptions();
        td.createTCodeProducts();
        td.createTCodeProductIncentives();
        TCode_Product__c tp = TestDataUtility.newTCodeProduct(td.lstZproducts[1].Id, td.lstTCodeManagement[0].Id);
        insert tp;

        TCode_Product_Incentive__c tpi = TestDataUtility.newTCodeProductIncentive(3, td.lstIncentives[1].Id, tp.Id, td.lstTCodeProductIncentives[0].Subscription_Type__c);
        insert tpi;

        for(Incentive__c i : td.lstIncentives){
            i.Is_Valid_For_Renewal__c = true;
        }
        update td.lstIncentives;

        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        Test.startTest();
            ctrl.subscriptionDetail = td.lstSubscriptions[0];
            ctrl.subscriptionDetail.TCode__c = td.lstTCodeManagement[0].Id;
            ctrl.accountDetail = td.lstIndividualSubscribers[0];
            ctrl.updateIncentives();
            System.assertEquals(td.lstZproducts[0].Id, ctrl.subscriptionDetail.Product__c);
            System.assertEquals(td.lstIncentives[0].Id, ctrl.activeIncentives[1].getValue());
            ctrl.changeProductId(td.lstZproducts[1].Id);
            System.assertEquals(td.lstZproducts[1].Id, ctrl.subscriptionDetail.Product__c);
            System.assertEquals(td.lstIncentives[1].Id, ctrl.activeIncentives[1].getValue());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 16/06/2016
    Version - 1.0
    Function - testing the calculation of the calculatePaymentStartDate() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testcalculatePaymentStartDate(){

        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        Test.startTest();
            Date result = ctrl.calculatePaymentStartDate(Date.newinstance(2016, 6, 10), '1');
            System.assertEquals(Date.newinstance(2016, 7, 1), result);

            result = ctrl.calculatePaymentStartDate(Date.newinstance(2016, 6, 10), '15');
            System.assertEquals(Date.newinstance(2016, 6, 15), result);

            result = ctrl.calculatePaymentStartDate(Date.newinstance(2016, 6, 16), '15');
            System.assertEquals(Date.newinstance(2016, 7, 15), result);

        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 16/06/2016
    Version - 1.2
    Function - testing the the upsertSubscriptionIncentive() method
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski 1.1       07/11/2016  modified logic
    Wiktor Czykin     1.2       31/01/2017  modified so that it is not time dependant
    ****************************************************************************************/
    private static testMethod void testupsertSubscriptionIncentive(){
        TestDataUtility testUtility = new TestDataUtility(1);
        testUtility.createSubscriptions();

        SubscriptionCallCentreRenewalController ctrl = new SubscriptionCallCentreRenewalController();
        ctrl.subscriptionDetail = testUtility.lstSubscriptions[0];
        ctrl.accountDetail = testUtility.lstIndividualSubscribers[0];

        ctrl.upsertSubscriptionIncentive();
        List<SubscriptionIncentiveAssociation__c> subIncentiveAssociation = [
            SELECT Subscriber__c, Subscription__c, Reason__c, Incentive__c
            FROM SubscriptionIncentiveAssociation__c
            LIMIT 1
        ];
        System.assert(!subIncentiveAssociation.isEmpty());
        System.assertEquals(testUtility.lstSubscriptions[0].Id, subIncentiveAssociation[0].Subscription__c);
        System.assertEquals(testUtility.lstIndividualSubscribers[0].Id, subIncentiveAssociation[0].Subscriber__c);
        System.assertEquals(null, subIncentiveAssociation[0].Reason__c);
        System.assertEquals(null, subIncentiveAssociation[0].Incentive__c);

        Incentive__c inc =  new Incentive__c(Name = 'n', Incentive_Description__c = 't', IncentiveValue__c = 5, Valid_From__c = System.today().addDays(-10), Valid_To__c = System.today().addDays(30), Is_Valid_For_Renewal__c = true);
        insert inc;

        ctrl.selectedIncentive = inc.Id;
        ctrl.selectedIncentiveReason = 'A reason';
        ctrl.upsertSubscriptionIncentive();

        subIncentiveAssociation = [
            SELECT Reason__c
            FROM SubscriptionIncentiveAssociation__c
            WHERE Incentive__c = :inc.Id
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        System.assertEquals('A reason', subIncentiveAssociation[0].Reason__c);
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 16/06/2016
    Version - 1.2
    Function - sucessfully run the saveAndTakePayment method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         06/09/2016  //made sure it works with new delivery type validation
    Wiktor Czykin   1.2         19/01/2017  //modified incentive assertion
    ****************************************************************************************/
    private static testMethod void testSuccessfulTakePayment(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createRetailers();
        tdu.createSubscriptions();
        tdu.createTCodeManagement();

        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        tdu.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        update tdu.lstTCodeManagement[0];

        tdu.lstIndividualSubscribers[0].FirstName = 'gavin';
        update tdu.lstIndividualSubscribers[0];

        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Lapsed';
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions[0];

        Subscription__c subscription = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, tdu.lstRetailers[0].Id, Date.today());
        subscription.Subscription_Status__c = 'Active';
        subscription.Payment_Type__c = Constants.SUB_PMETHOD_CC;
        subscription.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        insert subscription;

        Incentive__c inc =  new Incentive__c(Name = 'n', Incentive_Description__c = 't', IncentiveValue__c = 5, Valid_From__c = System.today().addDays(-10), Valid_To__c = System.today().addDays(30), Is_Valid_For_Renewal__c = true);
        insert inc;

        // query so that if_Is_Renewal_Binary__c gets assigned
        subscription = [
            SELECT if_Is_Renewal_Binary__c,
                Payment_Type__c,
                Previous_Subscription__c,
                Subscriber__c,
                Retailer__c ,
                Weekly_Price__c,
                Subscription_Status__c,
                Subscription_Duration_Picklist__c,
                Start_Date__c,
                Pricing_Error__c,
                Delivery_Type__c,
                Payment_Details_Received__c,
                Voucher_Pack_Duration__c,
                Asset_Calc__c,
                Liab_Calc__c,
                Renewal_Price_Override__c,
                Low_Start_Weekly_Price__c,
                Product__c,
                Astra_Migration_Balance__c,
                Revenue_Write_off_Amount__c
            FROM Subscription__c
            WHERE Id =:subscription.Id
        ];

        List<General__c> generalSettings = new List<General__c>{
            new General__c(Name = Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE, Value_Boolean__c = true),
            new General__c(Name = Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_CUTOFF, Value__c = '1'),
            new General__c(Name = Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME, Value__c = '1')
        };
        insert generalSettings;

        SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
        ctl.accountDetail = tdu.lstIndividualSubscribers[0];
        ctl.subscriptionDetail = subscription;
        ctl.selectedOrderMethod = 'coupon';
        ctl.selectedDelivery = subscription.Delivery_Type__c;
        ctl.initDeliveryOptions();
        ctl.selectedIncentive = inc.Id;
        ctl.selectedIncentiveReason = 'A reason';

        Test.startTest();
            PageReference pageResult = ctl.saveAndTakePayment();
            System.assertNotEquals(null, pageResult, ApexPages.getMessages());
            System.assert(ctl.bValidDeliveryType);
        Test.stopTest();

        System.assert(pageResult.getUrl().contains(Page.MppPaymentFrame.getUrl()));
        System.assertEquals('', pageResult.getParameters().get('incentiveId'));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 07/09/2016
    Version - 1.0
    Function - save subscription failure because of delivery type validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveSubFailure(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();

        SubscriptionCallCentreRenewalController ctl = new SubscriptionCallCentreRenewalController();
        ctl.displayedPaymentType = 'not cheque';
        ctl.subscriptionDetail = tdu.lstSubscriptions[0];
        ctl.selectedDelivery = ctl.subscriptionDetail.Delivery_Type__c;
        ctl.selectedOrderMethod = 'someOrderMethod';
        Test.startTest();
            ctl.initDeliveryOptions();
            System.assertEquals(2, ctl.lstDeliveryOptions.size());
            System.assert(ctl.bValidDeliveryType);
            ctl.setDeliveryOptions.remove(Constants.DELIVERYTYPE_HND);
            ctl.saveSub();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Renewal_Not_supported_delivery_type_for_selected_product),'found delivery option where should not');
            System.assert(!ctl.bValidDeliveryType);
        Test.stopTest();
    }
}