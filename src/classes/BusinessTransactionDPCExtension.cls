/**
* @author Pawel Chrzanowski
* @date 27/04/2016
* @description  Business Transaction Discretionary Price Change Controller Extension
#############Change Log#############
Modified by     Version Change Date
Wiktor Czykin   1.1     31/08/2016  //modified productSwitch()
Vishant Shah    1.2     05/10/2016  //Added isStatusPaymentFailure 'Payment Failure' - Jira 5125
**/
public class BusinessTransactionDPCExtension {

    public CoreApiResources.CoreApiOffersByProductAndFrequency offersByProductAndFrequencyCalloutResponse;
    public Boolean isStatusComplete {get;set;}
    public Boolean isStatusPaymentFailure {get;set;}
    public Boolean hasEligibleSubscription {get;set;}
    public Boolean showDiscPriceChangeButton {get;set;}
    public Boolean showDiscPriceChangeOfferList {get;set;}
    public Boolean showDiscPriceChangeSelectedOffer {get;set;}
    public Boolean showDiscPriceChangeResult {get;set;}
    public Business_Transaction__c bt {get;set;}
    public List<List<String>> lstDiscPriceChangeOffers {get;set;}
    public String selectedDiscPriceChangeOffer {get;set;}
    public String discPriceChangeFrequency {get;set;}
    public String discPriceChangeProduct {get;set;}
    public String resultMessage {get;set;}
    private Id btId;

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        27/04/2016
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Vishant Shah        1.2         05/10/2016
    ****************************************************************************************/
    public BusinessTransactionDPCExtension(ApexPages.StandardController stdController){
        btId = stdController.getId();
        isStatusComplete = false;
        hasEligibleSubscription = false;
        showDiscPriceChangeButton = true;
        showDiscPriceChangeOfferList = false;
        showDiscPriceChangeSelectedOffer = false;
        showDiscPriceChangeResult = false;
        discPriceChangeFrequency = '';
        discPriceChangeProduct = '';

        if(btId != null){
            List<Business_Transaction__c> lstBt = [select Name, Subscription__c, Subscription__r.Zuora__Zuora_Id__c, Subscription__r.Zuora__TermEndDate__c, Status__c from Business_Transaction__c where Id = :btId];
            if(!lstBt.isEmpty()){
            	bt = lstBt[0];
            }else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Business_Transaction_Not_Found));
				return;
            }

            if(String.isBlank(bt.Subscription__c)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Business_Transaction_Has_No_Related_Subscription));
				return;
            }

            if(String.isBlank(bt.Subscription__r.Zuora__Zuora_Id__c)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Subscription_Has_No_Zuora_Id));
				return;
            }

			if(String.isBlank(String.valueOf(bt.Subscription__r.Zuora__TermEndDate__c))){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Subscription_Has_No_TermEndDate));
				return;
	        }

        	List<Zuora__SubscriptionProductCharge__c> lstSubscriptionProductCharge = [select Zuora__BillingPeriod__c, Zuora__Product__c from Zuora__SubscriptionProductCharge__c where Zuora__Subscription__c =: bt.Subscription__c limit 1];
        	if(!lstSubscriptionProductCharge.isEmpty()){
        		if(String.isNotEmpty(lstSubscriptionProductCharge[0].Zuora__BillingPeriod__c) && lstSubscriptionProductCharge[0].Zuora__Product__c != null){
            		List<Zuora__Product__c> lstProduct = [select Name from Zuora__Product__c where Id =: lstSubscriptionProductCharge[0].Zuora__Product__c];
            		if(!lstProduct.isEmpty()){
            			hasEligibleSubscription = true;
            			isStatusComplete = bt.Status__c == Constants.BUSINESS_TRANSACTION_STATUS_COMPLETE;
                        isStatusPaymentFailure = bt.Status__c == Constants.BUSINESS_TRANSACTION_STATUS_PAYMENT_FAILURE;
            			discPriceChangeFrequency = lstSubscriptionProductCharge[0].Zuora__BillingPeriod__c;
						discPriceChangeProduct = EncodingUtil.urlEncode(lstProduct[0].Name, 'UTF-8');
            		}else{
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Subscription_Has_No_Rate_Plan_Charge_Product));
            		}
            	}else{
            		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Subscription_Rate_Plan_Charge_No_Period_Product));
            	}
        	}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Subscription_Has_No_Rate_Plan_Charge));
        	}
        }
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        03/05/2016
    Function    Show offers for Discretionary Price Change
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void showDiscPriceChangeOffers(){
        showDiscPriceChangeButton = false;
        showDiscPriceChangeOfferList = true;
        showDiscPriceChangeSelectedOffer = false;
        showDiscPriceChangeResult = false;
        selectedDiscPriceChangeOffer = '';
        lstDiscPriceChangeOffers = new List<List<String>>();

        //CoreApi callout
        offersByProductAndFrequencyCalloutResponse = CoreAPICalloutUtility.GetOffersByProductAndFrequency(discPriceChangeProduct, discPriceChangeFrequency);

        if(offersByProductAndFrequencyCalloutResponse != null && !offersByProductAndFrequencyCalloutResponse.offers.isEmpty()){
	        for(Integer i=0; i<offersByProductAndFrequencyCalloutResponse.offers.size(); i++){
	            lstDiscPriceChangeOffers.add(new List<String>{String.valueOf(i), offersByProductAndFrequencyCalloutResponse.offers[i].friendlyName.replace('&#163;', '£') + ' (' + offersByProductAndFrequencyCalloutResponse.offers[i].tmgId + ')'});
	        }
        }else{
        	hasEligibleSubscription = false;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offers_No_Matches));
        }
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        03/05/2016
    Function    Select offer for Discretionary Price Change
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void selectDiscPriceChangeOffer(){
        showDiscPriceChangeButton = false;
        showDiscPriceChangeOfferList = false;
        showDiscPriceChangeSelectedOffer = true;
        showDiscPriceChangeResult = false;
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        03/05/2016
    Function    Method to cancel Offer for Discretionary Price Change
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void cancelDiscPriceChangeOffer(){
        showDiscPriceChangeButton = false;
        showDiscPriceChangeOfferList = true;
        showDiscPriceChangeSelectedOffer = false;
        showDiscPriceChangeResult = false;
        selectedDiscPriceChangeOffer = '';
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        03/05/2016
    Function    Process Discretionary Price Change
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         31/08/2016 //added update of related business transaction with Agent Name
    ****************************************************************************************/
    public void discPriceChange(){
        showDiscPriceChangeButton = false;
        showDiscPriceChangeOfferList = false;
        showDiscPriceChangeSelectedOffer = false;
        showDiscPriceChangeResult = true;
        resultMessage = '';

        String subscriptionId = bt.Subscription__r.Zuora__Zuora_Id__c;
        String offerCode = offersByProductAndFrequencyCalloutResponse.offers[Integer.valueOf(selectedDiscPriceChangeOffer)].tmgId;
        Date d = Date.valueOf(bt.Subscription__r.Zuora__TermEndDate__c);
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        String effectiveDate = dt.format('yyyy-MM-dd') + 'T' + dt.format('HH:mm') + 'Z';

        //coreApi callout
        resultMessage = CoreAPICalloutUtility.putOffer(subscriptionId, offerCode, effectiveDate, bt.Name);

        try{
            if(btId != null){
                update new Business_Transaction__c(Id = btId, Agent_Name__c = UserInfo.getName());
            }
        }catch(DMLException e){
            //silent fail
        }
    }
}
