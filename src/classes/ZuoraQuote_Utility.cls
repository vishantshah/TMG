/**
* Author:       Sally ElGhoul (Accenture)
* Date:         22/10/2015
* Description:  this class is a utility class for Zuora Quote
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Sally ElGhoul     12/02/2016  get the name of zqu__QuoteRatePlanCharge__c
* Wiktor Czykin     10/05/2017  replaced calls to SoqlUtility with calls to GlobalQueries
**/
public class ZuoraQuote_Utility {
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        22/10/2015
    Function    Create a zuora quote and set the default values
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static zqu__Quote__c createZuoraQuote(Zuora.zApi api,account accountObj,string quoteSubscriptionType,Zuora__Subscription__c activeAccountSubscription){
        if(accountObj==null || String.isEmpty(quoteSubscriptionType)){
            return null;
        }
        zqu__Quote__c newQuoteObj = new zqu__Quote__c();
        //set the common quote default values
        setNewQuoteCommonDefaultValues(newQuoteObj,accountObj,quoteSubscriptionType);
        
        If(newQuoteObj.zqu__SubscriptionType__c==Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE){ //populate the payment method in case of new subscription only
            //set default values specific for new subscription quotes
            setNewSubscriptionQuoteDefaultVlues(newQuoteObj);
        }else if(newQuoteObj.zqu__SubscriptionType__c==Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE){
            //set default values specific for amendment quotes
            setAmendmentQuoteDefaultValues(api,newQuoteObj,accountObj,activeAccountSubscription);
        }
        return newQuoteObj;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        22/10/2015
    Function    Set the common default Values
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         06/01/2016
    ****************************************************************************************/
    public static zqu__Quote__c setNewQuoteCommonDefaultValues(zqu__Quote__c newQuoteObj,account accountObj,string quoteSubscriptionType){
        newQuoteObj.zqu__SubscriptionType__c=quoteSubscriptionType;
        newQuoteObj.zqu__Account__c=accountObj.id;   //Link the quote to the account
        newQuoteObj.zqu__StartDate__c=Date.today();  //Start Date
        newQuoteObj.zqu__ValidUntil__c=Date.today(); //Valid Until Date
        newQuoteObj.zqu__Service_Activation_Date__c=Date.today();//new Zuora dates by default to Today's date - using instead of Start Date
        newQuoteObj.zqu__InitialTerm__c=Constants.INITIAL_TERM_VALUE_DEFAULT; //Initial Term 
        newQuoteObj.zqu__RenewalTerm__c=Constants.RENEWAL_TERM_VALUE_DEFAULT; //Renewal Term    
        newQuoteObj.Acquisition_Channel__c=Constants.ACQUISITION_CHANNEL_CALL_CENTER_VALUE; //Acquisition channel should be call center
        newQuoteObj.zqu__PaymentGateway__c='';  //clear the payment gateway on the quote , to enable the change of gateway and adding new payment method
        newQuoteObj.zqu__RenewalSetting__c=Constants.RENEWAL_SETTING_VALUE; //set the renewal setting default value
        newQuoteObj.zqu__AutoRenew__c=true;                                 //set the auto renew
        newQuoteObj.zqu__Currency__c=Constants.ZUORA_ACCOUNT_CURRENCY_FIELD_VALUE; //set the currency default value
        newQuoteObj.zqu__Subscription_Term_Type__c=Constants.QUOTE_SUBSCRIPTION_TERM_TYPE; //set the subscription term type
        newQuoteObj.zqu__GenerateInvoice__c=true;
        
        //other fields 
        newQuoteObj.zqu__InvoiceProcessingOption__c=Constants.INVOICE_PROCESSING_OPTION_DEFAULT;
        newQuoteObj.zqu__Calculate_Quote_Metrics_Through__c=Constants.CALCULATE_QUOTE_METRICS_DEFAULT;
        newQuoteObj.zqu__ProcessPayment__c=true;
        newQuoteObj.zqu__ApplyCreditBalance__c=true;
        
        //Set the quote name to be "subscription number(Value)"+" Quote"
        newQuoteObj.Name= string.format(Constants.QUOTE_NAME_FORMAT,new list<string>{accountObj.Subscriber_Number__c}) ;
        
        // Find the contacts associated with the account         
        List<Contact> lstContacts = [SELECT Id, Name FROM Contact WHERE Account.Id = :accountObj.id];         
          
        // Assuming the contacts are present set the billTo and soldTo to the first contact         
        if  (lstContacts.size() > 0) {             
             newQuoteObj.zqu__BillToContact__c= lstContacts[0].Id;             
             newQuoteObj.zqu__SoldToContact__c= lstContacts[0].Id;             
        }
        
        return newQuoteObj;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        22/10/2015
    Function    Set default fields for new quotes
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         06/01/2016
    ****************************************************************************************/
    public static zqu__Quote__c setNewSubscriptionQuoteDefaultVlues(zqu__Quote__c newQuoteObj){
        newQuoteObj.zqu__PaymentMethod__c=Constants.CREDIT_CARD_PAYMENT_METHOD;     //Payment Method
        newQuoteObj.recordTypeId=RecordTypeUtility.getRecordTypeId(zqu__Quote__c.SObjectType, Constants.QUOTE_NEW_SUBSCRIPTION_RECORD_TYPE_NAME, zqu__Quote__c.class.getName()); 
        newQuoteObj.zqu__BillingMethod__c=Constants.BILLING_METHOD_DEFAULT;
        newQuoteObj.zqu__PaymentTerm__c=Constants.ZUORA_ACCOUNT_PAYMENT_TERM_FIELD_VALUE;
        newQuoteObj.zqu__BillCycleDay__c=Constants.BILL_CYCLE_DAY_DEFAULT_VALUE;
        return newQuoteObj;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        22/10/2015
    Function    set default values for amendments
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static zqu__Quote__c setAmendmentQuoteDefaultValues(Zuora.zApi api,zqu__Quote__c newQuoteObj,account accountObj,Zuora__Subscription__c activeAccountSubscription){
        
        //the quote start date should be the next billing cycle
        if(activeAccountSubscription.Zuora__NextChargeDate__c!=null){
            
            //1. check that the next charge date is not in the past to use it as the quote start date
            if(activeAccountSubscription.Zuora__NextChargeDate__c>=Date.today()){
                //we are using service activation date instead of nextcharge date
                newQuoteObj.zqu__Service_Activation_Date__c=activeAccountSubscription.Zuora__NextChargeDate__c; 
            } else{
                string strBillCycleDay=accountObj.Zuora__R00N40000001kyLcEAI__r[0].Zuora__BillCycleDay__c; // this will have the value 29th of the month
                string strBillCycleDayValueOnly=strBillCycleDay.mid(0, 1); //extrat the number only from 29th of the month or 2nd of the month
                if(strBillCycleDay.mid(1, 1).isNumeric()){
                    strBillCycleDayValueOnly+=strBillCycleDay.mid(1, 1);
                }
                
                integer BillCycleDay=integer.valueof(strBillCycleDayValueOnly);
                Date quoteStartDate=date.newinstance(Date.today().year(), Date.today().month(),getBillCycleDay(Date.today().year(), Date.today().month(), BillCycleDay));
                
                //2. if the next charge date is in the past, get the bill cycle day and use the current month 
                //   use this value is it is not in the paste
                if(quoteStartDate<Date.today()){
                    
                    //3. if the billcycle day of the current month is in the paste, use the bill cycle day of next month
                    quoteStartDate=date.newinstance(Date.today().year(), Date.today().AddMonths(1).month(),getBillCycleDay(Date.today().year(), Date.today().addMonths(1).month(), BillCycleDay));
                }   
                newQuoteObj.zqu__Service_Activation_Date__c = quoteStartDate;
            }
        }
        
        newQuoteObj.zqu__BillCycleDay__c=String.valueof(activeAccountSubscription.Zuora__SubscriptionStartDate__c.day()); //set the billing cycle day
        newQuoteObj.recordTypeId=RecordTypeUtility.getRecordTypeId(zqu__Quote__c.SObjectType, Constants.QUOTE_AMENDMENT_RECORD_TYPE_NAME, zqu__Quote__c.class.getName()); 
        newQuoteObj.zqu__ZuoraAccountID__c=activeAccountSubscription.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
        
        //get the latest subscription record from Zuora
        Zuora.ZObject zuoraLatestSubscription=Zuora_Utility.getLatestSubscriptionVersion(api,activeAccountSubscription.Original_Zuora_Subscription_ID__c);
        if(zuoraLatestSubscription!=null){
            newQuoteObj.zqu__ExistSubscriptionID__c= string.valueof(zuoraLatestSubscription.getValue('Id'));
            
            //other fields to fill using the subscroption record
            newQuoteObj.zqu__Hidden_Subscription_Name__c=string.valueof(zuoraLatestSubscription.getValue('Name'));
            newQuoteObj.zqu__SubscriptionVersion__c=integer.valueof(zuoraLatestSubscription.getValue('Version'));
            
            if ( !Test.isRunningTest() ){
                newQuoteObj.zqu__SubscriptionTermStartDate__c=date.valueof(zuoraLatestSubscription.getValue('SubscriptionStartDate'));
                newQuoteObj.zqu__SubscriptionTermEndDate__c=date.valueof(zuoraLatestSubscription.getValue('SubscriptionEndDate'));
            }else{
                newQuoteObj.zqu__SubscriptionTermStartDate__c=Date.today();
                newQuoteObj.zqu__SubscriptionTermEndDate__c=Date.today().addYears(1);
            }
            
        }else{system.debug(Constants.QUOTE_ERROR_GET_LATEST_ZUORA_SUBSCRIPTION);throw new TMGUtil.GenericException(Constants.QUOTE_ERROR_GET_LATEST_ZUORA_SUBSCRIPTION);return null;}
            
        newQuoteObj.zqu__Amendment_Name__c=String.format(Constants.QUOTE_AMENDMENT_NAME_FORMAT,new list<string>{newQuoteObj.Name}); //Quote Amendment Name field
        newQuoteObj.arePaymentDetailsEntered__c=true; //mark that the payment details are already entered in case of amendment quote because it is not mandatory that they enter their payment details again
            
        //fill the fields "Default Payment Method Type" and "Default Payment Details"
        list<Zuora__PaymentMethod__c> lstPayementMethods=[select Zuora__Type__c,Zuora__BankTransferAccountNumber__c, 
                                                                Zuora__CreditCardMaskNumber__c 
                                                                from Zuora__PaymentMethod__c 
                                                                where Zuora__DefaultPaymentMethod__c=true 
                                                                        and Zuora__PaymentMethodStatus__c='Active' 
                                                                        and Zuora__BillingAccount__c in 
                                                                            (select id from Zuora__CustomerAccount__c 
                                                                                where Zuora__Account__c=:accountObj.id 
                                                                                and Zuora__Status__c='Active')];
            
        if(lstPayementMethods!=null && lstPayementMethods.size()>0){
            
            if(lstPayementMethods[0].Zuora__Type__c==Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE){//payment is credit card
                newQuoteObj.Default_Payment_Method_Type__c=Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL;
                newQuoteObj.Default_Payment_Details__c=lstPayementMethods[0].Zuora__CreditCardMaskNumber__c;
            }else if(lstPayementMethods[0].Zuora__Type__c==Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE){//payment is bank tranfer "direct debit"
                newQuoteObj.Default_Payment_Method_Type__c=Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL;
                newQuoteObj.Default_Payment_Details__c=lstPayementMethods[0].Zuora__BankTransferAccountNumber__c;   
            }
        }
            
        //set the new amendment quote master field from the subscription master quote field
        newQuoteObj.Master_Quote__c=activeAccountSubscription.Master_Quote__c;
            
        //set the new amendment quote previous quote field from the subscription related quote field because it is still points 
        //to the previous quote
        //the subscription related quote filed will be update after sending the amendment quote to zbilling
        newQuoteObj.Previous_Quote__c=activeAccountSubscription.Related_Quote__c;
        id previousQuoteId=activeAccountSubscription.Related_Quote__c;
        
        //fill the qute QUOTE_SUBSCRIPTION_NEXT_CHARGE_DATE_FIELD with the value of the subscription
        if(activeAccountSubscription.Zuora__NextChargeDate__c!=null){
            newQuoteObj.Subscription_Next_Charge_Date__c= activeAccountSubscription.Zuora__NextChargeDate__c;
        } 
        
        //3. Sally elGhoul - 28/8/2015 fill the amendment quote Subscription_Term_Type__c field to be defaulted as the previous quote
        if(previousQuoteId!=null){
            list<zqu__Quote__c> lstPreviousQuote=[select Subscription_Origin__c,Subscription_Rate_Plan_Term_Type__c from zqu__Quote__c where id=:previousQuoteId];
            if(lstPreviousQuote!=null && lstPreviousQuote.size()>0){
                
                //in case of amendment, default the subscription origin to be as the previous quote
                newQuoteObj.Subscription_Origin__c=lstPreviousQuote[0].Subscription_Origin__c;
                
                //fill the Subscription_Term_Type__c
                if(!string.isempty(lstPreviousQuote[0].Subscription_Rate_Plan_Term_Type__c)){
                    newQuoteObj.Subscription_Rate_Plan_Term_Type__c=lstPreviousQuote[0].Subscription_Rate_Plan_Term_Type__c;
                    //this field is used to keep track the subscription term type before amendment
                    newQuoteObj.Previous_Subscription_RatePlan_Term_Type__c=lstPreviousQuote[0].Subscription_Rate_Plan_Term_Type__c;
                }
            }
        }
        return newQuoteObj;
    }
    
    //Use this function to get the correct billing cycle of the month
    public static integer getBillCycleDay(integer yearValue, integer MonthValue,integer billCycleDay){
        if(billCycleDay>date.daysInMonth(yearValue, MonthValue)){
            return date.daysInMonth(yearValue, MonthValue);
        }else{
            return billCycleDay;
        }
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        27/11/2015
    Function    This function is called to get the product rate plan details of the quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static zqu__QuoteRatePlan__c getQuoteProductRatePlan(Id quoteId){
        List<zqu__Quote__c> lstQuote=[select id, Master_Quote__c from zqu__Quote__c where id =:QuoteId];
        if(lstQuote!=null && lstQuote.size()>0){
            
            //if the master quote is not empty, we will get the product effective price added to the master quote
            //products are added only to master quote because amendments quotes are only for mid term discounts
            //no product change in amendment
            //also, the mid term discount is added only in amendment quotes
            id quoteIdVal=lstQuote[0].id;
            if(!String.isEmpty(lstQuote[0].Master_Quote__c)){
                quoteIdVal=lstQuote[0].Master_Quote__c;
            }
            System.debug('check quoteIdVal: '+quoteIdVal);
            
            //2. get the product rate plan on the master quote and the quote charge
            String quoteRatePlanSoql='select id,zqu__QuoteProductName__c,';
            quoteRatePlanSoql+='(Select zqu__EffectivePrice__c,zqu__Period__c From zqu__Quote_Rate_Plan_Charges__r) ';
            quoteRatePlanSoql+='From zqu__QuoteRatePlan__c ';
            quoteRatePlanSoql+='where (not Name like \'%'+Constants.DISCOUNT_RATE_PLAN_NAME+'%\') and zqu__Quote__c=\''+quoteIdVal+'\'';
            List<zqu__QuoteRatePlan__c> lstQuoteRatePlans=database.query(quoteRatePlanSoql);
            
            system.debug('check lstQuoteRatePlans: '+lstQuoteRatePlans);
            //we have only one non discount product per quote
            if(lstQuoteRatePlans!=null && lstQuoteRatePlans.size()>0){
                return lstQuoteRatePlans[0];
            }else{
                return null;
            }
        }
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    This function is called to get the All rate plan details of the quote
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       10/05/2017  //replaced query builder call
    ****************************************************************************************/
    public static List<zqu__QuoteRatePlan__c> getQuoteAllRatePlans(Id quoteId){
        String whereCondition='zqu__Quote__c=\''+quoteId+'\'';
        String quoteRatePlanSoql=GlobalQueries.queryBuilderSelectAll('zqu__QuoteRatePlan__c',null,whereCondition,null,'5000');
        
        //return the quote
        List<zqu__QuoteRatePlan__c> lstQuoteRatePlans = Database.query(quoteRatePlanSoql);
        if(lstQuoteRatePlans!=null && lstQuoteRatePlans.size()>0){
            return lstQuoteRatePlans;
        }
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        06/01/2016
    Function    This function is called to get the All the quote rate plan charges and it returns
                a map where the key is the quote rate plan Id of the quote and the the values is the list of charges
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.1         12/2/2016 get the name of zqu__QuoteRatePlanCharge__c
    ****************************************************************************************/
    public static Map<Id,list<zqu__QuoteRatePlanCharge__c>> getQuoteRatePlanCharges(List<zqu__QuoteRatePlan__c> lstQuoteRatePlans){
        Set<Id> setQuoteRatePlanIds=new Set<Id>();
        Map<Id,list<zqu__QuoteRatePlanCharge__c>> mapQuoteRatePlanCharges=new Map<Id, List<zqu__QuoteRatePlanCharge__c>>();
        
        if(lstQuoteRatePlans!=null && lstQuoteRatePlans.size()>0){
            //fill the set of quote rateplan ids
            for(zqu__QuoteRatePlan__c quoteRatePlanObj : lstQuoteRatePlans){
                if(!setQuoteRatePlanIds.contains(quoteRatePlanObj.id)){
                    setQuoteRatePlanIds.add(quoteRatePlanObj.id);
                }
            }
            
            //query and get all the quote rate plan charges
            List<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanCharges=[select id,name,zqu__EffectivePrice__c,zqu__Upto_How_Many_Periods__c,zqu__Period__c,zqu__Model__c,zqu__ProductRatePlanChargeZuoraId__c,zqu__QuoteRatePlan__c from zqu__QuoteRatePlanCharge__c where zqu__QuoteRatePlan__c in :setQuoteRatePlanIds];
            if(lstQuoteRatePlanCharges!=null && lstQuoteRatePlanCharges.size()>0){
                for(zqu__QuoteRatePlanCharge__c quoteRatePlanChargeObj : lstQuoteRatePlanCharges){
                    if(!mapQuoteRatePlanCharges.containsKey(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c)){
                        mapQuoteRatePlanCharges.put(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c, new List<zqu__QuoteRatePlanCharge__c>{quoteRatePlanChargeObj});
                    }else{
                        List<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanChargesTemp=mapQuoteRatePlanCharges.get(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c);
                        lstQuoteRatePlanChargesTemp.add(quoteRatePlanChargeObj);
                        mapQuoteRatePlanCharges.put(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c,lstQuoteRatePlanChargesTemp);
                    }
                }
            }   
        }
        return mapQuoteRatePlanCharges;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        6/01/2016
    Function    This function is called to get the quote record
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       10/05/2017  //replaced query builder call 
    ****************************************************************************************/
    public static zqu__Quote__c getQuoteRecord(id quoteId){
        if(String.isempty(quoteId)){
            throw new TMGUtil.GenericException('Quote Id must be passed.');
        }
        String whereCondition='id=\''+quoteId+'\'';
        String quoteSoql = GlobalQueries.queryBuilderSelectAll('zqu__Quote__c',null,whereCondition,null,'1');
        
        //return the quote
        List<zqu__Quote__c> lstQuotes=Database.query(quoteSoql);
        if(lstQuotes!=null && lstQuotes.size()>0){
            return lstQuotes[0];
        }
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        07/01/2016
    Function    This function is called to get the All quote amendments of the quote
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       10/05/2017  //replaced query builder call 
    ****************************************************************************************/
    public static list<zqu__QuoteAmendment__c> getQuoteAllAmendments(Id quoteId){
        String whereCondition='zqu__Quote__c=\''+quoteId+'\'';
        String quoteAmendmentSoql = GlobalQueries.queryBuilderSelectAll('zqu__QuoteAmendment__c',null,whereCondition,null,'5000');
        
        //return the quote
        list<zqu__QuoteAmendment__c> lstQuoteAmendments=Database.query(quoteAmendmentSoql);
        if(lstQuoteAmendments!=null && lstQuoteAmendments.size()>0){
            return lstQuoteAmendments;
        }
                
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        07/01/2016
    Function    This function is called to get the All quote amendments Rate plans
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Map<Id, List<zqu__QuoteRatePlan__c>> getQuoteAmendmentRatePlans(List<zqu__QuoteAmendment__c> lstQuoteAmendments){
        Map<Id,List<zqu__QuoteRatePlan__c>> mapQuoteAmendmentRatePlans=new Map<Id,List<zqu__QuoteRatePlan__c>>();
        Set<Id> setQuoteAmendmentIds=new Set<Id>();
        
        if(lstQuoteAmendments!=null){
            //get the quote amendment Ids
            for(zqu__QuoteAmendment__c quoteAmendObj : lstQuoteAmendments){
                if(!setQuoteAmendmentIds.contains(quoteAmendObj.id)){
                    setQuoteAmendmentIds.add(quoteAmendObj.id);
                }
            }
            
            //get the quote rate plans for the quote amendments
            List<zqu__QuoteRatePlan__c> lstQuoteAmendmentRatePlans=[select id,zqu__QuoteAmendment__c,zqu__ProductRatePlanZuoraId__c from zqu__QuoteRatePlan__c where zqu__QuoteAmendment__c in :setQuoteAmendmentIds];
            if(lstQuoteAmendmentRatePlans!=null){
                for(zqu__QuoteRatePlan__c quoteRatePlanObj : lstQuoteAmendmentRatePlans){
                    
                    if(!mapQuoteAmendmentRatePlans.containsKey(quoteRatePlanObj.zqu__QuoteAmendment__c)){
                        mapQuoteAmendmentRatePlans.put(quoteRatePlanObj.zqu__QuoteAmendment__c,new List<zqu__QuoteRatePlan__c>{quoteRatePlanObj});
                    }else{
                        List<zqu__QuoteRatePlan__c> lstQuoteAmendmentRatePlansTemp=mapQuoteAmendmentRatePlans.get(quoteRatePlanObj.zqu__QuoteAmendment__c);
                        lstQuoteAmendmentRatePlansTemp.add(quoteRatePlanObj);
                        mapQuoteAmendmentRatePlans.put(quoteRatePlanObj.zqu__QuoteAmendment__c,lstQuoteAmendmentRatePlansTemp);
                    }
                }
            }   
        }
        
        return mapQuoteAmendmentRatePlans;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        07/01/2016
    Function    This function is called to get the All quote amendments Rate plan chages
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.1         12/2/2016 get the name of zqu__QuoteRatePlanCharge__c
    ****************************************************************************************/
    public static Map<id,List<zqu__QuoteRatePlanCharge__c>> getQuoteAmendmentRatePlanCharges(List<zqu__QuoteRatePlan__c> lstQuoteAmendmentRatePlans){
        
        //return variable
        Map<Id,List<zqu__QuoteRatePlanCharge__c>> mapQuoteAmendmentRatePlanCharges=new Map<Id,List<zqu__QuoteRatePlanCharge__c>>();
        Set<Id> setQuoteRatePlans=new Set<Id>();
        
        if(lstQuoteAmendmentRatePlans!=null){
            
            //get the quote amendment rate plan Ids
            for(zqu__QuoteRatePlan__c quoteRatePlanObj : lstQuoteAmendmentRatePlans){
                if(!setQuoteRatePlans.contains(quoteRatePlanObj.id)){
                    setQuoteRatePlans.add(quoteRatePlanObj.id);
                }
            }
            
            //get the quote amendment rate Plans Charges
            List<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanCharges=[select id,name,zqu__EffectivePrice__c,zqu__Upto_How_Many_Periods__c,zqu__Period__c,zqu__QuoteRatePlan__c,zqu__ProductRatePlanChargeZuoraId__c,zqu__Model__c from zqu__QuoteRatePlanCharge__c where zqu__QuoteRatePlan__c in :setQuoteRatePlans];
            
            if(lstQuoteRatePlanCharges!=null && lstQuoteRatePlanCharges.size()>0){
                for(zqu__QuoteRatePlanCharge__c quoteRatePlanChargeObj : lstQuoteRatePlanCharges){
                    
                    if(!mapQuoteAmendmentRatePlanCharges.containsKey(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c)){
                        mapQuoteAmendmentRatePlanCharges.put(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c,new List<zqu__QuoteRatePlanCharge__c>{quoteRatePlanChargeObj});
                    }else{
                        List<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanChargesTemp=mapQuoteAmendmentRatePlanCharges.get(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c);
                        lstQuoteRatePlanChargesTemp.add(quoteRatePlanChargeObj);
                        mapQuoteAmendmentRatePlanCharges.put(quoteRatePlanChargeObj.zqu__QuoteRatePlan__c,lstQuoteRatePlanChargesTemp);
                    }
                }
            }
        }
        
        return mapQuoteAmendmentRatePlanCharges;
    }
}