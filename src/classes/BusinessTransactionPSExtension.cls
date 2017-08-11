/**
* @author Pawel Chrzanowski
* @date 27/04/2016
* @description  Business Transaction Product Switch Controller Extension
#############Change Log#############
Modified by     Version Change Date
Wiktor Czykin   1.1     31/08/2016  //modified productSwitch()
Vishant Shah    1.2     05/10/2016  //Added isStatusPaymentFailure 'Payment Failure' - Jira 5125
**/
public class BusinessTransactionPSExtension {

    public Boolean isStatusComplete {get;set;}
    public Boolean isStatusPaymentFailure {get;set;}
    public Boolean hasAlternativeOffers {get;set;}
    public Boolean showOfferList {get;set;}
    public Boolean showProductSwitchDate {get;set;}
    public Boolean showProductSwitchResult {get;set;}
    public Boolean switchBtnDisabled {get;set;}
    public Business_Transaction__c bt {get;set;}
    public List<List<String>> lstAlternativeOffers {get;set;}
    public List<SelectOption> lstDateOptions {get;set;}
    public String selectedOffer {get;set;}
    public String selectedDate {get;set;}
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
    public BusinessTransactionPSExtension(ApexPages.StandardController stdController) {
        btId = stdController.getId();
        isStatusComplete = false;
        isStatusPaymentFailure = false;
        lstAlternativeOffers = new List<List<String>>();
        hasAlternativeOffers = false;
        showOfferList = true;
        showProductSwitchDate = false;
        showProductSwitchResult = false;
        lstDateOptions = new List<SelectOption>();
        lstDateOptions.add(new SelectOption(Constants.OFFER_SWITCH_DATE_IMMEDIATE, Constants.OFFER_SWITCH_DATE_IMMEDIATE));

        if(btId != null){
            List<Business_Transaction__c> lstBt = [select Alternative_Offers__c, Alternative_Offers_Names__c, Name, Subscription__c, Subscription__r.Zuora__Zuora_Id__c, Subscription__r.Zuora__TermEndDate__c, Status__c from Business_Transaction__c where Id = :btId];
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

            if(!String.isBlank(bt.Alternative_Offers__c)){
                if(!String.isBlank(bt.Alternative_Offers_Names__c)){
                    List<String> lstAlternativeOfferIds = bt.Alternative_Offers__c.split(',');
                    List<String> lstAlternativeOfferNames = bt.Alternative_Offers_Names__c.split(',');
                    if(lstAlternativeOfferIds.size() == lstAlternativeOfferNames.size()){
                        hasAlternativeOffers = true;
                        isStatusComplete = bt.Status__c == Constants.BUSINESS_TRANSACTION_STATUS_COMPLETE;
                        isStatusPaymentFailure = bt.Status__c == Constants.BUSINESS_TRANSACTION_STATUS_PAYMENT_FAILURE;
                        lstDateOptions.add(new SelectOption(Constants.OFFER_SWITCH_DATE_END_OF_TERM, Constants.OFFER_SWITCH_DATE_END_OF_TERM + ' (' + String.valueOf(Date.valueOf(bt.Subscription__r.Zuora__TermEndDate__c)) + ')'));
                        for(Integer i=0; i<lstAlternativeOfferIds.size(); i++){
                            lstAlternativeOffers.add(new List<String>{String.valueOf(i), lstAlternativeOfferIds[i], lstAlternativeOfferNames[i]});
                        }
                    }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Alternative_Offers_Names_Mismatch));
                    }
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Alternative_Offers_No_Names));
                }
            }
        }
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        27/04/2016
    Function    Method to select Offer for Product Switch
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void selectOffer(){
        showOfferList = false;
        showProductSwitchDate = true;
        showProductSwitchResult = false;
        selectedDate = '';
        switchBtnDisabled = true;
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        27/04/2016
    Function    Method to select Offer Date for Product Switch
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void selectDate(){
        switchBtnDisabled = false;
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        27/04/2016
    Function    Method to cancel Offer for Product Switch
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void cancelOffer(){
        showOfferList = true;
        showProductSwitchDate = false;
        showProductSwitchResult = false;
        selectedOffer = '';
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        27/04/2016
    Function    Product Switch to an alternative offer
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         31/08/2016 //added update of related business transaction with Agent Name
    ****************************************************************************************/
    public void productSwitch(){
        showOfferList = false;
        showProductSwitchDate = false;
        showProductSwitchResult = true;
        resultMessage = '';

        String subscriptionId = bt.Subscription__r.Zuora__Zuora_Id__c;
        String offerCode = lstAlternativeOffers[Integer.valueOf(selectedOffer)][1];
        Date d;

        if(selectedDate == Constants.OFFER_SWITCH_DATE_IMMEDIATE){
        	d = Date.today();
        }else if(selectedDate == Constants.OFFER_SWITCH_DATE_END_OF_TERM){
        	d = Date.valueOf(bt.Subscription__r.Zuora__TermEndDate__c);
        }
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        String effectiveDate = dt.format('yyyy-MM-dd') + 'T' + dt.format('HH:mm') + 'Z';

        //coreApi Callout
        resultMessage = CoreAPICalloutUtility.sendUpgrade(subscriptionId, offerCode, effectiveDate, bt.Name);

        try{
            if(btId != null){
                update new Business_Transaction__c(Id = btId, Agent_Name__c = UserInfo.getName());
            }
        }catch(DMLException e){
            //silent fail
        }
    }

}
