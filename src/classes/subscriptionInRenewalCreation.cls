/**
* @author Unknown
* @date Unknown
* @description  Class called by new subscriptionInRenewalTrigger and subscriptionInRenwalButton classes.
                Creates a new 'Offered' subscription with fields populated with values from the current subscription.
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin       1.1     30/07/2015  //cleaned up a bit, removed hardcoded record type ids
Cristina Anghenie   1.2     19/08/2015  //pre-populate PaymentDate and Frequence when new subscription is created
Cristina Anghenie   1.3     14/09/2015  //update MppDDCalloutStage__c to manualRenewal only when renewal button is clicked on the subscription page
Wiktor Czykin       1.4     24/08/2015  //modified handleRenewedSubscriptions() to support (eg. low start) price overides
Pawel Chrzanowski   1.5     01/04/2016  //added functionality for new data model
Michal Szewczyk     1.6     01/07/2016  //modified to use price plans for product and price renewal override.
Wiktor Czykin       1.7     13/07/2016  //modified handleRenewedSubscriptions();
Lynette Lim         1.8     25/07/2016  //Removed Rank__c field from all Price Plan logic
Wiktor Czykin       1.9     27/09/2016  //modified handleRenewedSubscriptions()
Pawel Chrzanowski   2.0     27/01/2017  //modified handleRenewedSubscriptions()
Wiktor Czykin       2.1     07/04/2017  //modified handleRenewedSubscriptions()
**/
public class subscriptionInRenewalCreation {

    @TestVisible private static void raiseError(Subscription__c p_CurrentSub, String p_Message, String p_Source) {
        p_CurrentSub.Pricing_Error__c = true;
        System.debug(p_Message);

        if (p_Source=='trigger') {
            p_CurrentSub.addError (p_Message);
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.9
    Function -  //creates new subscriptions and populate initial values
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         24/08/2015  //added weekly price override
    Pawel Chrzanowski   1.2         01/04/2016  //modified function for new data model
    Lynette Lim         1.3         06/04/2016  //updated to stop subscription auto-renewal if no price plan is found
    Michal Szewczyk     1.4         01/07/2016  //modified to use price plans for product and price renewal override.
    Wiktor Czykin       1.5         13/07/2016  //added constants, made Plan__c field copied over from previous sub
    Lynette Lim         1.6         25/07/2016  //Removed Rank__c field from Price Plan logic
    Wiktor Czykin       1.7         27/09/2016  //modified the logic to only copy through Plan reference if products are same,
                                                else sub trigger will populate the default plan for the new product
    Pawel Chrzanowski   1.8         27/01/2017  //modified to not reload Plan on default if Product is changed
    Wiktor Czykin       1.9         07/04/2017  //added 0 value as a valid one
    ****************************************************************************************/
    public static Map<Id,Id> handleRenewedSubscriptions(Map<Id, Subscription__c> p_RenewalSubs, String p_Source){
        Map<Id, Id> curSubNewSubMap = new Map<Id, Id>();
        Subscription__c[] subsToBeCreated = new Subscription__c[]{};
        String mppDDCalloutStage;

        List<TCodeManagement__c> tcodes = [SELECT Id, Name FROM TCodeManagement__c WHERE Type__c = :Constants.TCODE_TYPE_RENEWAL AND Valid__c = true AND Name = :Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME];
        if(tcodes.isEmpty()) {
            throw new TelegraphApplicationException( 'Unable to find a renewal TCode');
        }

        //Price override
        Set<Id> setSubsWithPlanId = new Set<Id>();
        Map<String, List<Subscription__c>> subPlanProductsMap = new Map<String, List<Subscription__c>>();
        Map<Id, Double> subsWithoutPriceOverrideRenewalPriceMap = new Map<Id, Double>();
        Map<Id, Double> subsWithoutPriceOverrideRenewalDiscountMap = new Map<Id, Double>();
        Map<Id, String> subsPlanProductOverrideMap = new Map<Id, String>();
        for(Subscription__c sub : p_RenewalSubs.values()){
            if( sub.Plan__c != null){
                setSubsWithPlanId.add(sub.Plan__c);
                String keyMap = String.valueOf(sub.Plan__c);
                List<Subscription__c> lstSub = new List<Subscription__c>();
                if(subPlanProductsMap.containsKey(keyMap)){
                    lstSub = subPlanProductsMap.get(keyMap);
                    lstSub.add(sub);
                    subPlanProductsMap.put(keyMap,lstSub);
                } else {
                    lstSub.add(sub);
                    subPlanProductsMap.put(keyMap,lstSub);
                }
            }
        }
        //map plan Id to lst of subscriptions
        List<Price_Plan__c> lstPricePlan = [SELECT  Plan__c, Product_To__c, Renewal_Price__c, Low_Price__c, High_Price__c, Incentive_Discount__c
                                            FROM Price_Plan__c
                                            WHERE Plan__c IN :setSubsWithPlanId
                                            AND Product_To__c != null
                                            ];

        Set<String> oneRecOnly = new Set<String>();
        if(!lstPricePlan.isEmpty()){
            for(Price_Plan__c pp : lstPricePlan){
                String key = String.valueOf(pp.Plan__c);
                if(subPlanProductsMap.containsKey(key)){
                    for(Subscription__c subTmp :subPlanProductsMap.get(key)) {
                        String uniqueKey = String.valueOf(subTmp.Id) + '_' +String.valueOf(pp.Plan__c);
                        if(subTmp.Weekly_Price__c >= pp.Low_Price__c && subTmp.Weekly_Price__c <= pp.High_Price__c){
                            if(oneRecOnly.contains(uniqueKey)) {
                                 throw new TelegraphApplicationException('Found more then one price plan meeting criteria.');
                            }
                            oneRecOnly.add(uniqueKey);
                            subsWithoutPriceOverrideRenewalPriceMap.put(subTmp.Id, pp.Renewal_Price__c);
                            subsWithoutPriceOverrideRenewalDiscountMap.put(subTmp.Id, pp.Incentive_Discount__c);
                            subsPlanProductOverrideMap.put(subTmp.Id,pp.Product_To__c);
                        }
                    }
                }
            }
        }

        for(Subscription__c subs : p_RenewalSubs.values()){
            Id renewalProduct;
            Double renewalPrice;
            Double renewalIncentive;
            Boolean found = false;

            //Product override
            if(subs.Renewal_Product_Override__c != null){
                renewalProduct = subs.Renewal_Product_Override__c;
            }else{
                renewalProduct =  subsPlanProductOverrideMap.get(subs.Id);
            }

            //Price override
            if(subs.Renewal_Price_Override__c != null && subs.Renewal_Price_Override__c >= 0){
                renewalPrice = subs.Renewal_Price_Override__c;
                renewalIncentive = 0;
                found = true;
            }else if(subsWithoutPriceOverrideRenewalPriceMap.get(subs.Id) != null && subsWithoutPriceOverrideRenewalPriceMap.get(subs.Id) >= 0){
                renewalPrice = subsWithoutPriceOverrideRenewalPriceMap.get(subs.Id);
                renewalIncentive = subsWithoutPriceOverrideRenewalDiscountMap.get(subs.Id);
                found = true;
            }

            //If no price band found, and source is a trigger, set Pricing_Error__c field on Subscription and do not create new subscription
            //If source is the button then allow creation
            System.debug('found = '+found+' source = '+p_Source);
            if(!found && p_Source == 'trigger'){
                subs.Pricing_Error__c = true;
                continue;
            }else if(p_Source == 'button'){
                mppDDCalloutStage = subs.IsContinuous__c ? Constants.MPP_MANUALRENEWAL_STAGE : null;
            }

            //Create new sub and populate fields
            Subscription__c newSub = new Subscription__c(   Subscription_Status__c = Constants.SSTATUS_OFFERED,
                                                            Subscriber__c = subs.Subscriber__c,
                                                            Previous_Subscription__c = subs.Id,
                                                            Retailer__c = subs.Retailer__c,
                                                            Product__c = renewalProduct,
                                                            Discount__c = renewalIncentive,
                                                            Weekly_Price__c = renewalPrice,
                                                            Previous_Subscription_Expiry__c = subs.End_Date__c,
                                                            Previous_Price__c = subs.Weekly_Price__c,
                                                            Delivery_Type__c = subs.Delivery_Type__c,
                                                            Payment_Type__c = subs.Payment_type__c,
                                                            //Set Subscription_Duration_Picklist__c value based on New_Sub_Duration__c. Knock off the decimal point and zero.
                                                            Subscription_Duration_Picklist__c = String.valueOf(subs.New_Sub_Duration__c).subString(0,2),
                                                            MppDDCalloutStage__c = mppDDCalloutStage,
                                                            Order_Taken_Method__c = 'Auto Renewal',
                                                            Order_Taken_Date__c = Date.today(),
                                                            TCode__c = tcodes[0].Id,
                                                            IsContinuous__c = subs.Payment_type__c.equalsIgnoreCase(Constants.SUB_PMETHOD_DD) ? true : subs.IsContinuous__c,
                                                            MPP_CC_Frequency__c = subs.MPP_CC_Frequency__c,
                                                            MPP_DD_Frequency__c = subs.MPP_DD_Frequency__c,
                                                            PaymentDate__c = subs.PaymentDate__c,
                                                            Plan__c = subs.Plan__c
                                                        );
            //Set start date to monday following current subscription expiry
            if(subs.End_Date__c != null){
                newSub.Start_Date__c = subs.End_Date__c.addDays(1);
            }

            if(subs.Subscriber__r.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_ACCOUNT_SCHOOL, Account.class.getName())){
                newSub.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
            }else if(subs.RecordTypeId == RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName())){
                newSub.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName());
            }else if(subs.RecordTypeId != null){
                newSub.RecordTypeId = subs.RecordTypeId;
            }
            subsToBeCreated.add(newSub);
        }

        //if any new subscriptions need to be created
        if (subsToBeCreated.size()>0) {
            Database.SaveResult[] saveResults = Database.Insert(subsToBeCreated, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()){
                    // add id to list of created subscriptions
                    curSubNewSubMap.put(subsToBeCreated[i].Previous_Subscription__c, saveResults[i].getId());
                }else{
                    // add error to current subscription
                    Subscription__c currentSub = p_RenewalSubs.get(subsToBeCreated[i].Previous_Subscription__c);
                    raiseError(currentSub,'Unable to create new subscription: ' + saveResults[i].getErrors()[0], p_Source);
                }
            }
        }
        return curSubNewSubMap;
    }
}
