/**
* Author:       Sally ElGhoul (Tquila)
* Date:         09/07/2015
* Description:  this class for testing ZQuoteSubscriptionTriggerHandler
*
* ******************* Change Log *******************
* Modified by           Change Date
* Wiktor Czykin         09/08/2016  //improved test coverage
* Michal Szewczyk       23/08/2016  //changed testSyncUpdateAccountStatusOnInsert()
* Mantas Grigaliunas    10/10/2016  //added new test method testUpdateZuoraSubscriptionCampaignCode()
* Wiktor Czykin         10/02/2017  //updated test methods to work with changed logic, added failure coverage methods
* Mantas Grigaliunas    08/05/2017  //removed assertion on testUpdateZuoraSubscriptionCampaignCode()
* Wiktor Czykin         12/06/2017  //added testCreateSubscriptionIncentive();
**/
@isTest
private class ZQuoteSubscriptionTriggerHandlerTest {

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        08/08/2015
    Function    Test account status update on subscription inserts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         Changed some Replatform Digital Statuses for Active
    ****************************************************************************************/
    private static testMethod void testSyncUpdateAccountStatusOnInsert() {
        TestDataUtility td = new TestDataUtility(4);
        td.checkZSubscriptionDependencies();
        List<Zuora__Subscription__c> lstSubsToInsert = new List<Zuora__Subscription__c>();
        List<String> lstStatuses = new List<String>{Constants.SUBSCRIPTION_ACTIVE_STATUS,
                                                    Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS,
                                                    Constants.SUBSCRIPTION_CANCELLED_STATUS,
                                                    Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS
        };
        for(Integer i = 0; i < td.iCounter; i++){
            for(Integer j = i; j<lstStatuses.size(); j++){
                Zuora__Subscription__c zs = TestDataUtility.newZSubscription(i*j, td.lstRegistrants[i].Id, td.lstBillingAccount[i].Id);
                zs.Zuora__Status__c = lstStatuses[j];
                lstSubsToInsert.add(zs);
            }
        }
        Test.startTest();
            insert lstSubsToInsert;
        Test.stopTest();
        Map<Id, Account> mapRefetch = new Map<Id, Account>([select Id, Replatform_Digital_Status__c from Account where Id in : td.lstRegistrants]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[0].Id).Replatform_Digital_Status__c);
        System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[1].Id).Replatform_Digital_Status__c);
        System.assertEquals(Constants.SUBSCRIBER_INACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[2].Id).Replatform_Digital_Status__c);
        System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[3].Id).Replatform_Digital_Status__c);
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        10/02/2017
    Function    Test account status update on subscription inserts failure
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSyncUpdateAccountStatusOnInsertFailure() {
        TestDataUtility td = new TestDataUtility(4);
        td.checkZSubscriptionDependencies();
        List<Zuora__Subscription__c> lstSubsToInsert = new List<Zuora__Subscription__c>();
        List<String> lstStatuses = new List<String>{Constants.SUBSCRIPTION_ACTIVE_STATUS,
                                                    Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS,
                                                    Constants.SUBSCRIPTION_CANCELLED_STATUS,
                                                    Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS
        };
        for(Integer i = 0; i < td.iCounter; i++){
            for(Integer j = i; j<lstStatuses.size(); j++){
                Zuora__Subscription__c zs = TestDataUtility.newZSubscription(i*j, td.lstRegistrants[i].Id, td.lstBillingAccount[i].Id);
                zs.Zuora__Status__c = lstStatuses[j];
                lstSubsToInsert.add(zs);
            }
        }
        System.runAs(TestDataUtility.newUser(10, td.getProfileIdForName(Constants.PROFILE_WEB_API))){
            td.lstRegistrants[0].PersonMailingCity = null;
            td.lstRegistrants[0].Phone = '012316546';
            td.lstRegistrants[2].PersonMailingCity = null;
            td.lstRegistrants[2].Phone = '012316546';
            update new List<Account>{td.lstRegistrants[0], td.lstRegistrants[2]};
        }

        Test.startTest();
            List<Database.SaveResult> lstResult = Database.insert(lstSubsToInsert, false);
            Integer i = 0;
            for(Database.SaveResult sr : lstResult){
                if(!sr.isSuccess()) i++;           
            }
            System.assertEquals(6, i); //4 subs for first and 2 subs for 3rd
        Test.stopTest();
        Map<Id, Account> mapRefetch = new Map<Id, Account>([select Id, Replatform_Digital_Status__c from Account where Id in : td.lstRegistrants]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        System.assertEquals(Constants.LITE_ACCOUNT_DIGITAL_STATUS, mapRefetch.get(td.lstRegistrants[0].Id).Replatform_Digital_Status__c);
        System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[1].Id).Replatform_Digital_Status__c);
        System.assertEquals(Constants.LITE_ACCOUNT_DIGITAL_STATUS, mapRefetch.get(td.lstRegistrants[2].Id).Replatform_Digital_Status__c);
        System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[3].Id).Replatform_Digital_Status__c);
        List<WebService_Log__c> lstWL = [select Id from WebService_Log__c where Endpoint__c = :Constants.LOG_TRIGGER_ENDPOINT];
        System.assertEquals(1, lstWL.size());
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        09/08/2015
    Function    Test account status update on subscription updates - update of status on subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSyncUpdateAccountStatusOnUpdate() {
        TestDataUtility td = new TestDataUtility(4);
        td.createZSubscriptions();
        List<Zuora__Subscription__c> lstSubsToInsert = new List<Zuora__Subscription__c>();
        List<String> lstStatuses = new List<String>{Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS,
                                                    Constants.SUBSCRIPTION_CANCELLED_STATUS,
                                                    Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS
        };
        for(Integer i = 0; i < td.iCounter; i++){
            lstSubsToInsert.add(TestDataUtility.newZSubscription(i*2, td.lstRegistrants[i].Id, td.lstBillingAccount[i].Id));
        }
        insert lstSubsToInsert;

        for(Zuora__Subscription__c subscription : td.lstZuoraSubscriptions){
            subscription.Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
        }
        for(Zuora__Subscription__c subscription : lstSubsToInsert){
            subscription.Zuora__Status__c = Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS;
        }

        Test.startTest();
            td.lstZuoraSubscriptions.addAll(lstSubsToInsert);
            update td.lstZuoraSubscriptions;
        Test.stopTest();
        Map<Id, Account> mapRefetch = new Map<Id, Account>([select Id, Replatform_Digital_Status__c from Account where Id in : td.lstRegistrants]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        for(Account acc : mapRefetch.values()){
            System.assertEquals(Constants.SUBSCRIBER_INACTIVE_STATUS, acc.Replatform_Digital_Status__c);
        }
    }

     /***************************************************************************************
    Developer   Wiktor Czykin
    Date        09/08/2015
    Function    Test account status update on subscription updates - update of status on subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSyncUpdateAccountStatusOnUpdateFailure() {
        TestDataUtility td = new TestDataUtility(2);
        td.createZSubscriptions();
        List<Zuora__Subscription__c> lstSubsToInsert = new List<Zuora__Subscription__c>();
        for(Integer i = 0; i < td.iCounter; i++){
            lstSubsToInsert.add(TestDataUtility.newZSubscription(i*2, td.lstRegistrants[i].Id, td.lstBillingAccount[i].Id));
        }
        insert lstSubsToInsert;

        for(Zuora__Subscription__c subscription : lstSubsToInsert){
            subscription.Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
        }
        td.lstZuoraSubscriptions[1].Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
        System.runAs(TestDataUtility.newUser(10, td.getProfileIdForName(Constants.PROFILE_WEB_API))){
            td.lstRegistrants[0].PersonMailingCity = null;
            td.lstRegistrants[0].Phone = '012316546';
            update td.lstRegistrants[0];
        }

        Test.startTest();
            lstSubsToInsert.add(td.lstZuoraSubscriptions[1]);
            List<Database.SaveResult> lstResult = Database.update(lstSubsToInsert, false);
            Integer i = 0;
            for(Database.SaveResult sr : lstResult){
                if(!sr.isSuccess()) i++;           
            }
            System.assertEquals(1, i, lstResult);
        Test.stopTest();
        Map<Id, Account> mapRefetch = new Map<Id, Account>([select Id, Replatform_Digital_Status__c from Account where Id in : td.lstRegistrants]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, mapRefetch.get(td.lstRegistrants[0].Id).Replatform_Digital_Status__c);    
        System.assertEquals(Constants.SUBSCRIBER_INACTIVE_STATUS,  mapRefetch.get(td.lstRegistrants[1].Id).Replatform_Digital_Status__c); 
        List<WebService_Log__c> lstWL = [select Id, Event_Name__c from WebService_Log__c where Endpoint__c = :Constants.LOG_TRIGGER_ENDPOINT];
        System.assertEquals(2, lstWL.size()); //2 logs as two failures - marketing flags update and status update   
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        09/08/2015
    Function    Test account status update on subscription updates - update promo code and product on subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSyncUpdateAccountStatusOnUpdatePromoCodeAndProductChange() {
        TestDataUtility td = new TestDataUtility(4);
        td.createZProduct();
        td.createZSubscriptions();

        List<Zuora__Subscription__c> lstSubsToInsert = new List<Zuora__Subscription__c>();
        for(Integer i = 0; i < td.iCounter; i++){
            Zuora__Subscription__c zs = TestDataUtility.newZSubscription(i*2, td.lstRegistrants[i].Id, td.lstBillingAccount[i].Id);
            zs.Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
            lstSubsToInsert.add(zs);
        }
        insert lstSubsToInsert;
        Map<Id, Account> mapRefetch = new Map<Id, Account>([select Id, Replatform_Digital_Status__c from Account where Id in : td.lstRegistrants]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        for(Account acc : mapRefetch.values()){
            System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, acc.Replatform_Digital_Status__c);
        }

        Test.startTest();
            td.lstZuoraSubscriptions[0].PromoCode__c = 'somethingElse';
            td.lstZuoraSubscriptions[1].PromoCode__c = 'somethingElse';
            td.lstZuoraSubscriptions[2].Subscription_Product__c = 'somethingElse';
            td.lstZuoraSubscriptions[3].Subscription_Product__c = 'somethingElse';
            td.lstZuoraSubscriptions[0].Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
            td.lstZuoraSubscriptions[1].Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
            td.lstZuoraSubscriptions[2].Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
            td.lstZuoraSubscriptions[3].Zuora__Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
            update td.lstZuoraSubscriptions;
        Test.stopTest();

        mapRefetch = new Map<Id, Account>([select Id, Replatform_Digital_Status__c from Account where Id in : td.lstRegistrants]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        for(Account acc : mapRefetch.values()){
            System.assertEquals(Constants.SUBSCRIBER_INACTIVE_STATUS, acc.Replatform_Digital_Status__c);
        }
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        09/08/2015
    Function    Test link to quotes
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testLinkSubscriptionToQuote(){
        TestDataUtility td = new TestDataUtility(2);
        String sKey1 = 'someId1';
        String sKey2 = 'someId2';
        td.createZquotes();
        td.lstZQuotes[0].zqu__ZuoraSubscriptionID__c = sKey1;
        td.lstZQuotes[1].zqu__ZuoraSubscriptionID__c = sKey2;
        update td.lstZQuotes;

        td.checkZSubscriptionDependencies();

        Zuora__Subscription__c zs1 = TestDataUtility.newZSubscription(0, td.lstRegistrants[0].Id, td.lstBillingAccount[0].Id);
        zs1.Zuora__Zuora_Id__c = sKey1;
        Zuora__Subscription__c zs2 = TestDataUtility.newZSubscription(1, td.lstRegistrants[1].Id, td.lstBillingAccount[1].Id);
        zs2.Zuora__Zuora_Id__c = sKey2;
        List<Zuora__Subscription__c> lstSubsToInsert = new List<Zuora__Subscription__c>{zs1, zs2};

        Test.startTest();
            insert lstSubsToInsert;
        Test.stopTest();
        Map<Id, Zuora__Subscription__c> mapRefetch = new Map<Id, Zuora__Subscription__c>([select Id, Master_Quote__c, Related_Quote__c from Zuora__Subscription__c where Id in : lstSubsToInsert]);
        System.assert(!mapRefetch.isEmpty());
        System.assertEquals(td.iCounter, mapRefetch.size());
        System.assertEquals(td.lstZQuotes[0].Id, mapRefetch.get(zs1.Id).Master_Quote__c);
        System.assertEquals(td.lstZQuotes[0].Id, mapRefetch.get(zs1.Id).Related_Quote__c);
        System.assertEquals(td.lstZQuotes[1].Id, mapRefetch.get(zs2.Id).Master_Quote__c);
        System.assertEquals(td.lstZQuotes[1].Id, mapRefetch.get(zs2.Id).Related_Quote__c);
    }

    /***************************************************************************************
    Developer   Mantas Grigaliunas
    Date        10/10/2016
    Function    Test updateZuoraSubscriptionCampaignCode
    ******************* Change Log *******************
    Modified by           Change Date
    Mantas Grigaliunas    08/05/2017  //removed assertion for Zuora log as it would happen only on failure
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    private static void testSyncZuoraCampaignCode(){
        final String CAMPAIGN_CODE = 'Test';
        TestDataUtility td = new TestDataUtility(1);
        td.createZSubscriptions();
        System.assertEquals(null, td.lstZuoraSubscriptions[0].CampaignCode__c);

        Test.startTest();
        Zuora__Subscription__c subToUpdate = new Zuora__Subscription__c(
            Id = td.lstZuoraSubscriptions[0].Id, 
            CampaignCode__c = CAMPAIGN_CODE
        );
        update subToUpdate;
        Test.stopTest();
        Zuora__Subscription__c updatedSub = [ SELECT Id, CampaignCode__c FROM Zuora__Subscription__c WHERE Id = :subToUpdate.Id LIMIT 1 ];
        System.assertEquals(CAMPAIGN_CODE, updatedSub.CampaignCode__c);
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        12/06/2017
    Function    test for createSubscriptionIncentive() method in trigger
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCreateSubscriptionIncentive(){
        TestDataUtility td = new TestDataUtility(3);
        td.loadGeneral();
        td.createTCodeProductOffers();
        td.createIncentives();
        td.checkZSubscriptionDependencies();

        List<TCode_Product_Incentive__c> lstTCodeProductIncentives = new List<TCode_Product_Incentive__c>();
        Integer z = 0;
        for(TCode_Product__c tp : td.lstTCodeProductOffers){
            TCode_Product_Incentive__c tpi = TestDataUtility.newTCodeProductIncentive(z, td.lstIncentives[z].Id, tp.Id, null);
            tpi.Auto_Assign_for_Zuora_Subscription__c = true;
            lstTCodeProductIncentives.add(tpi);
            z++;
        }
        insert lstTCodeProductIncentives;

        List<Zuora__Subscription__c> lstSubs = new List<Zuora__Subscription__c>();
        for(Integer i = 0; i<td.iCounter; i++){
            Zuora__Subscription__c zs = TestDataUtility.newZSubscription(i, td.lstRegistrants[i].Id, td.lstBillingAccount[i].Id);
            zs.PromoCode__c = td.lstOffers[i].Name;
            zs.CampaignCode__c = td.lstTCodeManagement[i].Name;
            lstSubs.add(zs);
        }
        Test.startTest();
           insert lstSubs; 
        Test.stopTest();
    }
}