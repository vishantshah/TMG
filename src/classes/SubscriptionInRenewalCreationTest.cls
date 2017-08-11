/**
* @author Pawel Chrzanowski
* @date 04/04/2016
* @description Test class for SubscriptionInRenewalCreation
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk  1.1         04/07/2016  - fixed test methods
Wiktor Czykin    1.2         13/07/2016  - modified handleRenewedSubscriptionsTestPositive()
Wiktor Czykin    1.3         27/09/2016  - modified handleRenewedSubscriptionsTestPositive()
**/
@isTest
private class SubscriptionInRenewalCreationTest {
    private static final Double INCENTIVE_DISCOUNT = 4.50;
    private static final Double INCENTIVE_DISCOUNT_2 = 5.50;
    private static final Double RENEWAL_PRICE_OVERRIDE = 7.50;
    private static final Double HIGHER_THAN_HIGH_PRICE = 250;

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/04/2016
    Version - 1.1
    Function - test method for handleRenewedSubscriptions() negative scenario - no Tcode
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk  1.1         04/07/2016  - uncommented
    ****************************************************************************************/
    static testMethod void handleRenewedSubscriptionsTestNoTcode(){
        Map<Id, Id> subIdsMap = new Map<Id, Id>();
        Map<Id, Subscription__c> inRenewalSubsMap = new Map<Id, Subscription__c>();

        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        inRenewalSubsMap.put(td.lstSubscriptions[0].Id, td.lstSubscriptions[0]);

        Test.startTest();
            try{
                subIdsMap = subscriptionInRenewalCreation.handleRenewedSubscriptions(inRenewalSubsMap, '');
            }catch(Exception e){
                System.assert(e.getMessage().contains('Unable to find a renewal TCode'));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/04/2016
    Version - 1.1
    Function - test method for handleRenewedSubscriptions() negative scenario - no Product linked to subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk  1.1         04/07/2016  - uncommented and fixed
    ******************************************************************************************/
    static testMethod void handleRenewedSubscriptionsTestNoProduct(){
        Map<Id, Id> subIdsMap = new Map<Id, Id>();
        Map<Id, Subscription__c> inRenewalSubsMap = new Map<Id, Subscription__c>();

        TestDataUtility td = new TestDataUtility(1);
        td.loadCountryCodes();
        td.createTCodeManagement();
        td.createSubscriptions();

        td.lstTCodeManagement[0].Name = 'RNWL';
        td.lstTCodeManagement[0].Type__c = 'Renewal';
        update td.lstTCodeManagement[0];
        String subId = td.lstSubscriptions[0].Id;
        String sQuery = 'select ' + GlobalQueries.generateFieldsListForQuery(Subscription__c.class.getName(), new Set<String>{'Subscriber__r.RecordTypeId'}, null) + ' from Subscription__c where Id =:subId';
        List<Subscription__c> lstSubscription = Database.query(sQuery);
        inRenewalSubsMap.put(lstSubscription[0].Id, lstSubscription[0]);

        Test.startTest();

            try{
                subIdsMap = subscriptionInRenewalCreation.handleRenewedSubscriptions(inRenewalSubsMap, '');
            }catch(Exception e){
                System.assert(e.getMessage().contains('Subscription has no related Product.'));
            }

        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/04/2016
    Version - 1.3
    Function - test method for handleRenewedSubscriptions() positive scenario
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk  1.1         04/07/2016  - uncommented and fixed
    Wiktor Czykin    1.2         13/07/2016  - added assertions for Plan__c
    Wiktor Czykin    1.3         27/09/2016  - modified plan logic and assertions because of plan based on product logic
    ******************************************************************************************/
    static testMethod void handleRenewedSubscriptionsTestPositive(){
        List<Subscription__c> lstSubscriptions;
        Map<Id, Id> subIdsMapFromButton = new Map<Id, Id>();
        Map<Id, Id> subIdsMapFromTrigger = new Map<Id, Id>();
        Map<Id, Subscription__c> inRenewalSubsMapFromTrigger = new Map<Id, Subscription__c>();
        Map<Id, Subscription__c> inRenewalSubsMapFromButton = new Map<Id, Subscription__c>();

        TestDataUtility td = new TestDataUtility(8);
        td.createTCodeManagement();
        td.createSubscriptions();
        td.createZProduct();
        td.createPricePlans();

        td.lstTCodeManagement[0].Name = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_RENEWAL;
        update td.lstTCodeManagement[0];

        td.lstPricePlans[1].Product_From__c = td.lstZproducts[1].Id;
        td.lstPricePlans[1].Product_To__c = td.lstZproducts[5].Id;
        td.lstPricePlans[1].Incentive_Discount__c = INCENTIVE_DISCOUNT;
        td.lstPricePlans[2].Product_From__c = td.lstZproducts[2].Id;
        td.lstPricePlans[2].Product_To__c = td.lstZproducts[6].Id;
        td.lstPricePlans[3].Product_From__c = td.lstZproducts[3].Id;
        td.lstPricePlans[3].Product_To__c = td.lstZproducts[3].Id;
        update td.lstPricePlans;

        td.lstZproducts[5].Default_Plan__c = td.lstPlans[5].Id;
        update td.lstZProducts;

        //refetch subscriptions to populate formula fields
        lstSubscriptions = [select Discount__c, Plan__c, Product__c, Renewal_Price_Override__c, Renewal_Product_Override__c, Subscription_Status__c, Weekly_Price__c,
                            Subscription_Duration_Number_Override__c, Subscription_Duration_Picklist__c, Subscription_Duration_Number__c, New_Sub_Duration__c,
                            Subscriber__c, Retailer__c, End_Date__c, Delivery_Type__c, Payment_Type__c, PaymentDate__c, IsContinuous__c,
                            MPP_CC_Frequency__c, MPP_DD_Frequency__c, MppDDCalloutStage__c from Subscription__c];

        //Product - Id override, Weekly Price - value override
        lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
        lstSubscriptions[0].Product__c = td.lstZproducts[0].Id;
        lstSubscriptions[0].Renewal_Product_Override__c = td.lstZproducts[4].Id;
        lstSubscriptions[0].Renewal_Price_Override__c = RENEWAL_PRICE_OVERRIDE;
        lstSubscriptions[0].IsContinuous__c = true;
        inRenewalSubsMapFromButton.put(lstSubscriptions[0].Id, lstSubscriptions[0]);

        //Product - Id override, Weekly Price - trigger override success
        lstSubscriptions[1].Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
        lstSubscriptions[1].Product__c = td.lstZproducts[1].Id;
        lstSubscriptions[1].Renewal_Product_Override__c = td.lstZproducts[5].Id;
        lstSubscriptions[1].Renewal_Price_Override__c = null;
        lstSubscriptions[1].Plan__c = td.lstPlans[1].Id;
        lstSubscriptions[1].Weekly_Price__c = (td.lstPricePlans[1].Low_Price__c + td.lstPricePlans[1].High_Price__c)/2;
        inRenewalSubsMapFromButton.put(lstSubscriptions[1].Id, lstSubscriptions[1]);

        //Product - Id override, Weekly Price - trigger negative scenario
        lstSubscriptions[2].Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
        lstSubscriptions[2].Product__c = td.lstZproducts[2].Id;
        lstSubscriptions[2].Renewal_Product_Override__c = td.lstZproducts[6].Id;
        lstSubscriptions[2].Renewal_Price_Override__c = null;
        lstSubscriptions[2].Plan__c = td.lstPlans[2].Id;
        lstSubscriptions[2].Weekly_Price__c = HIGHER_THAN_HIGH_PRICE;
        lstSubscriptions[2].Discount__c = INCENTIVE_DISCOUNT_2;
        inRenewalSubsMapFromTrigger.put(lstSubscriptions[2].Id, lstSubscriptions[2]);

        //Product - trigger override, Weekly Price - trigger override success
        lstSubscriptions[3].Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
        lstSubscriptions[3].Product__c = td.lstZproducts[3].Id;
        lstSubscriptions[3].Renewal_Product_Override__c = null;
        lstSubscriptions[3].Renewal_Price_Override__c = null;
        lstSubscriptions[3].Plan__c = td.lstPlans[3].Id;
        lstSubscriptions[3].Weekly_Price__c = (td.lstPricePlans[3].Low_Price__c + td.lstPricePlans[3].High_Price__c)/2;
        inRenewalSubsMapFromButton.put(lstSubscriptions[3].Id, lstSubscriptions[3]);

        Test.startTest();

            //map containing InRenewal Ids => Offered Ids
            subIdsMapFromButton = subscriptionInRenewalCreation.handleRenewedSubscriptions(inRenewalSubsMapFromButton, 'button');
            subIdsMapFromTrigger = subscriptionInRenewalCreation.handleRenewedSubscriptions(inRenewalSubsMapFromTrigger, 'trigger');

            //button logic
            if(!subIdsMapFromButton.isEmpty()){
                Map<Id, Subscription__c> offeredSubsMapFromButton = new Map<Id, Subscription__c>([select Id, Plan__c, Discount__c, MppDDCalloutStage__c, Product__c, Subscription_Status__c, Weekly_Price__c from Subscription__c where Id in :subIdsMapFromButton.values()]);

                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[0].Id)).Subscription_Status__c, Constants.SSTATUS_OFFERED);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[0].Id)).Product__c, td.lstZproducts[4].Id);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[0].Id)).Weekly_Price__c, RENEWAL_PRICE_OVERRIDE);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[0].Id)).Discount__c, 0);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[0].Id)).MppDDCalloutStage__c, Constants.MPP_MANUALRENEWAL_STAGE);

                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[1].Id)).Subscription_Status__c, Constants.SSTATUS_OFFERED);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[1].Id)).Product__c, td.lstZproducts[5].Id);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[1].Id)).Weekly_Price__c, td.lstPricePlans[1].Renewal_Price__c);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[1].Id)).Discount__c, INCENTIVE_DISCOUNT);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[1].Id)).MppDDCalloutStage__c, null);
                System.assertEquals(td.lstPlans[1].Id, offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[1].Id)).Plan__c);


                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[3].Id)).Subscription_Status__c, Constants.SSTATUS_OFFERED);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[3].Id)).Product__c, td.lstZproducts[3].Id);
                System.assertEquals(offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[3].Id)).Weekly_Price__c, td.lstPricePlans[3].Renewal_Price__c);
                System.assertEquals(td.lstPlans[3].Id, offeredSubsMapFromButton.get(subIdsMapFromButton.get(lstSubscriptions[3].Id)).Plan__c);

            }

            //trigger logic
            //if Price Plan not found and source is trigger - don't create an offered subscription
            System.assert(subIdsMapFromTrigger.isEmpty());
        Test.stopTest();
    }
}
