/**
* @author Unknown
* @date Unknown
* @description This classs is used to calculate the deferred revenue against the subscription.
#############Change Log#############
Modified by         	Version     Change Date
Wiktor Czykin       	1.1         17/06/2015  //removed logic referencing old payment objects, introduced Old_Payment_Method_Total__c field and its usage (contains old payment methods)
                                            	//removed old way of subscriptions population within Calculation class - they are now fetched within based on passed in set of subs ids
                                            	//removed pointless interface
Mantas Grigaliunas	1.3         13/01/2016  //added functionality to update DD_Not_Completed_Payments_Sum__c field on Subscription
Mantas Grigaliunas  1.2         18/11/2016  //replaced Voucher Activity Refund Due field with Refund Status
Mantas Grigaliunas  1.4         20/02/2017  //added back refund due field condition
**/
public class DeferredCalculation {

    public static Boolean inDeferredCalc;
    public static Boolean isTestScenario;

    static final String DEF_ASSET = 'Asset';
    static final String DEF_REVENUE = 'Revenue';
    static final String DEF_VOUCHER = 'Voucher';

    static final String VOUCH_SENT = 'Vouchers Sent';
    static final String VOUCH_RECV = 'Vouchers Received';
    static final String VOUCH_GOODWILL = 'Goodwill';

    static final String PLANHIST_SUCCESS = 'Successful';
    static final String CHQ_SUBPAYMENT = 'Sub Payment';
    static final String CHQ_BANKED = 'Banked';
    static final String CHQ_REFUND = 'Refund';
    static final String CHQ_CANCELLED = 'Cancelled';
    static final String CHQ_INDEM = 'Indemnity Cheque';
    static final String CHQ_ANOM = 'Anomaly Cheque';
    static final String CARD_AUTH = 'Authorised';
    static final String CARD_SALE = 'Sale';
    static final String CARD_REFUND = 'Refund';
    static final Integer DD_PAYMENT_DURATION = 5;

    public virtual class CalculationClass{

        @TestVisible protected Map<Id, Subscription__c> mapSubscription;
        @TestVisible protected Map<Id, List<Decimal>> mapSubscriptionSums;

        @TestVisible protected List<Voucher_Adjustment__c> vouchers;
        @TestVisible protected List<Cheque__c> cheques;
        @TestVisible protected List<MPP_Transaction_History__c> mppTransactions; // payment details from MPP transactions

        protected Boolean bAssetUpdated = false;
        protected Boolean bRevUpdated = false;

        public String calcType { get; set; }

        public CalculationClass(){
            this.mapSubscription = new Map<Id, Subscription__c>();
            this.mapSubscriptionSums = new Map<Id, List<Decimal>>();//used to store calc values for each sub; [0] is Asset, [1] is Liab, [2] is Gross Payment
        }

        /***************************************************************************************
        Developer - Wiktor Czykin
        Date - 17/06/2015
        Version - 1.0
        Function -  this method replaced old addSubForProcessing();
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public void addSubsForProcessing(Set<Id> setSubscriptionIds){
            for(Subscription__c subscription : [select  Id,
                                                        Name,
                                                        Asset_Calc__c,
                                                        Liab_Calc__c,
                                                        Is_Using_MPP__c,
                                                        Payment_Type__c,
                                                        Total_DD_Payment__c,
                                                        Old_Payment_Method_Total__c
                                                    from Subscription__c
                                                    where Id in :setSubscriptionIds
                            ]){
                this.mapSubscription.put(subscription.Id, subscription);
                this.mapSubscriptionSums.put(subscription.Id, new List<Decimal>{0,0,0,0});
            }
        }

        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 1.1
        Function - fetches subscription related items
        #############Change Log#############
        Modified by         Version     Change Date
        Wiktor Czykin       1.1         18/06/2015  //just formatting
        Mantas Grigaliunas  1.2         13/01/2016  //added additional field to mppTranactions query
        ****************************************************************************************/
        public void GetSubData() {
            //get associated data
            this.vouchers = [select Id,
                                    Name,
                                    Voucher_Activity_Action__c,
                                    SystemModstamp,
                                    Subscription__c,
                                    Start_Date__c,
                                    Refund_Amount__c,
                                    Number_of_Vouchers__c,
                                    End_Date__c,
                                    Date_Vouchers_Received__c,
                                    Adjustment_Type__c,
                                    Voucher_Value__c,
                                    Refund_Status__c,
                                    Deferred_Asset_Value__c,
                                    Refund_Due__c
                                from Voucher_Adjustment__c
                                where Subscription__c in :this.mapSubscription.keySet()];

            this.cheques = [select  Id,
                                    Name,
                                    Type__c,
                                    Subscription__c,
                                    Ref_Number_on_Cheque__c,
                                    Raised__c,
                                    Name_on_Cheque__c,
                                    Cheque_Batch__c,
                                    Cheque_Banking_Status__c,
                                    Cheque_Amount__c,
                                    Agresso_Reference__c,
                                    Account_Number__c
                                from Cheque__c c
                                where Subscription__c in :this.mapSubscription.keySet()];

			this.mppTransactions = [select  Payment_Status__c,
                                            Payment_Type__c,
                                            Payment_Date__c,
                                            Total_Price__c,
                                            Subscription__c
                                        from MPP_Transaction_History__c
                                        where Subscription__c in :this.mapSubscription.keySet()
                                        and DD_Transaction_Type__c != 'AUDDIS'];
        }

        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 1.1
        Function - dispatches to proper counting method depending on calcType
        #############Change Log#############
        Modified by     Version     Change Date
        Wiktor Czykin   1.1         18/06/2015  //changed method names
        ****************************************************************************************/
        public void Calculate() {
            if (this.calcType == DEF_ASSET || this.calcType == DEF_VOUCHER) {
                this.calculateDefAsset();
            }

            if (this.calcType == DEF_REVENUE || this.calcType == DEF_VOUCHER) {
                this.calculateDefRevenue();
            }
        }

        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 1.1
        Function - updates subscription calculation values
        #############Change Log#############
        Modified by         Version     Change Date
        Mantas Grigaliunas  1.1        13/01/2016  //added DD_Not_Completed_Payments_Sum__c field assignment
        ****************************************************************************************/
        public Boolean UpdateValues() {
            List<Subscription__c> lstToUpdate = new List<Subscription__c>();
            for (Subscription__c subscription : this.mapSubscription.values()) {
                lstToUpdate.add( new Subscription__c(   Id = subscription.Id,
                                                        Asset_Calc__c = subscription.Asset_Calc__c,
                                                        Liab_Calc__c = subscription.Liab_Calc__c,
                                                        Sum_of_Payments__c = subscription.Sum_of_Payments__c,
                                                        DD_Not_Completed_Payments_Sum__c = subscription.DD_Not_Completed_Payments_Sum__c)
                );
            }

            if (this.bAssetUpdated || this.bRevUpdated) {
                Database.Saveresult[] res = Database.update(lstToUpdate);
            }
            return true;
        }

        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 1.1
        Function - counts Voucher_Adjustment__c voucher values
        #############Change Log#############
        Modified by     Version     Change Date
        Wiktor Czykin   1.1         18/06/2015  //cleaned up a bit only. no logic change
        ****************************************************************************************/
        private void calculateDefAsset() {
            for (Voucher_Adjustment__c v : this.vouchers) {
                Decimal defassetVal = 0;
                // voucher resends
                if (v.Voucher_Activity_Action__c == VOUCH_SENT) {
                    defassetVal += v.Voucher_Value__c;
                }

                if (v.Voucher_Activity_Action__c == VOUCH_RECV && v.Date_Vouchers_Received__c != null) {
                    if (v.Deferred_Asset_Value__c != null) {
                        defassetVal -= v.Deferred_Asset_Value__c;
                    }
                }
                //this if is exclusive from the above, so in particular data setup it is possible that same value is gonna be counted twice
                if (v.Adjustment_Type__c == VOUCH_GOODWILL) {
                    defassetVal -= v.Voucher_Value__c;
                }

                List<Decimal> curassetVal = this.mapSubscriptionSums.get(v.Subscription__c);
                curassetVal[0] += defassetVal;
                this.mapSubscriptionSums.put(v.Subscription__c, curassetVal);
            }

            // write back to subscription records
            for (Id subId : this.mapSubscriptionSums.keySet()) {
                if (this.mapSubscription.containsKey(subId)) {
                    this.mapSubscription.get(subId).Asset_Calc__c = this.mapSubscriptionSums.get(subId)[0];
                }
            }
            this.bAssetUpdated = true;
        }

        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 1.1
        Function -  populates Liab_Calc__c and Sum_of_Payments__c on subscription based on factors that are impacting the revenue (MPP/Voucher Activity/Cheque)
        #############Change Log#############
        Modified by         Version     Change Date
        Wiktor Czykin       1.1         19/06/2015  //removed old payment methods, added Old_Payment_Method_Total__c to the sum
	Mantas Grigaliunas  1.3         13/01/2016  //updated constants
                                                    //added functionality to update DD_Not_Completed_Payments_Sum__c field
        Mantas Grigaliunas  1.2         18/11/2016  //replaced Voucher Activity Refund Due field with Refund Status
        Mantas Grigaliunas  1.4         20/02/2017  //added back refund due field condition
        ****************************************************************************************/
        private void calculateDefRevenue() {
            Decimal dValue = 0;
            Decimal notCompletedDDvalue;
            // cheque payments
            for (Cheque__c chq : cheques) {
                dValue = 0;
                if (chq.Type__c == CHQ_REFUND || chq.Type__c == CHQ_INDEM) {
                    if (chq.Cheque_Banking_Status__c != CHQ_CANCELLED){//For cancelled cheques that had a type refund should NOT be included in calcs SMS-325
	                    dValue -= chq.Cheque_Amount__c;
                	}
                }
                if ((chq.Type__c == CHQ_SUBPAYMENT || chq.Type__c == CHQ_ANOM) && chq.Cheque_Banking_Status__c == CHQ_BANKED) {
                    dValue += chq.Cheque_Amount__c;
                }
                List<Decimal> lstValues = this.mapSubscriptionSums.get(chq.Subscription__c);
                lstValues[1] += dValue;
                lstValues[2] += dValue;
                this.mapSubscriptionSums.put(chq.Subscription__c, lstValues);
            }

            // MPP Transactions
			for(MPP_Transaction_History__c txn : this.mppTransactions){
                dValue = 0;
                notCompletedDDvalue = 0;
                if (txn.Payment_Status__c == Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND) {
                    dValue -= txn.Total_Price__c;
                }
                else if (txn.Payment_Status__c == Constants.MPPTRANSACTION_PAYMENTSTATUS_SUCCESS) {
                    dValue += txn.Total_Price__c;
                }

                if(txn.Payment_Date__c != null){
                    Date paymentDate = Date.newInstance(txn.Payment_Date__c.year(), txn.Payment_Date__c.month(), txn.Payment_Date__c.day());
                    if (txn.Payment_Status__c == Constants.MPPTRANSACTION_PAYMENTSTATUS_SUCCESS
                        && txn.Payment_Type__c == Constants.MPP_PAYMENTMETHOD_DD
                        && paymentDate > Date.today().addDays(-DD_PAYMENT_DURATION)) {
                        notCompletedDDvalue += txn.Total_Price__c;
                    }
                }
                
                List<Decimal> lstValues =  this.mapSubscriptionSums.get(txn.Subscription__c);
                lstValues[1] += dValue;
                lstValues[2] += dValue;
                lstValues[3] += notCompletedDDvalue;
                this.mapSubscriptionSums.put(txn.Subscription__c, lstValues );
            }

            // voucher returns
            for (Voucher_Adjustment__c v : vouchers) {
                dValue = 0;
                // returns
                if (v.Voucher_Activity_Action__c == VOUCH_RECV && v.Date_Vouchers_Received__c != null
                    && ( (v.Adjustment_Type__c != Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN && v.Refund_Due__c == true) 
                    || v.Adjustment_Type__c == Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN) ){
                    dValue += v.Voucher_Value__c;
                }
                List<Decimal> lstValues = this.mapSubscriptionSums.get(v.Subscription__c);
                lstValues[1] += dValue;
                this.mapSubscriptionSums.put(v.Subscription__c, lstValues);
            }

            // write back to procSubs
            for (Id subId : this.mapSubscriptionSums.keySet()) {
                if(this.mapSubscription.containsKey(subId)) {
                    Subscription__c subscription = this.mapSubscription.get(subId);
                    subscription.Liab_Calc__c = this.mapSubscriptionSums.get(subId)[1];
                    subscription.Sum_of_Payments__c = this.mapSubscriptionSums.get(subId)[2];
                    subscription.DD_Not_Completed_Payments_Sum__c = this.mapSubscriptionSums.get(subId)[3];
                    if(subscription.Old_Payment_Method_Total__c != null){
                        subscription.Liab_Calc__c += subscription.Old_Payment_Method_Total__c;
                        subscription.Sum_of_Payments__c += subscription.Old_Payment_Method_Total__c;
                    }
                }
            }
            this.bRevUpdated = true;
        }
    }

    //below classes, when instantiated, just define which calculation logic is gonna be executed
    public class DeferredAssetCalc extends CalculationClass {
        public DeferredAssetCalc() {
            super();
            this.calcType = DEF_ASSET;
        }
    }

    public class DeferredRevenueCalc extends CalculationClass {
        public DeferredRevenueCalc () {
            super();
            this.calcType = DEF_REVENUE;
        }
    }

    public class DeferredVoucherCalc extends CalculationClass {
        public DeferredVoucherCalc () {
            super();
            this.calcType = DEF_VOUCHER;
        }
    }
}