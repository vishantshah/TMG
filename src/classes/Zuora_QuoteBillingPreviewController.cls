/**
* Author:       Sally ElGhoul (Accenture)
* Date:         21/12/2015
* Description:  this class is controller to the component Zuora_QuoteBillingPreview
*
* ******************* Change Log *******************
* Modified by       Change Date    
  Sally ElGhoul  1.1 on 1/2/2016 extend the component to preview billing on quote,subscripton and account 
  Michal Kwika   1.2 3/2/2016 - new paramter to hIde messages from Billing Preview component
  Michal Szewczyk 1.3 12/2/2016 - change invoice numbering 
  Sally ElGhoul  1.4  15/2/2016 - Passing Subscription Service activation Date to billing preview instead of the start Date so I need to query it while getting subscription
  Sally ElGhoul  1.5  25/2/2016 - Remove the invoiceItem class and fillInvoiceItemsList method and use the ones in billing preview utility
  Michal Szewczyk 1.6 31/08/2016 - Changed GetSubscriptionBillingPreviewDetails() and GetAccountBillingPreviewDetails()
**/
public class Zuora_QuoteBillingPreviewController {

  //Private variables
    private zqu__Quote__c quoteObj; 
    private Id accountId;
    private Zuora.zApi zApiInstance = new Zuora.zApi();
    private Boolean isCalculateCreditBalance{
      get{
        if(Application_Settings__c.getInstance(Constants.CALCULATE_CREDIT_BALANCE_FOR_BILLING_PREVIEW)!=null){
          return Boolean.valueOf(Application_Settings__c.getInstance(Constants.CALCULATE_CREDIT_BALANCE_FOR_BILLING_PREVIEW).value__c);
        }else{
          return true;
        }
      }
    }
    private Boolean isMonthly;

    //public variables
    public ID quoteIDValue            {get;set;} //used for billing preview on quote page layout before send to zbilling
    public ID subscriptionIDValue       {get;set;} //Used for subscription preview on the subscription page layout , I pass the SF subscription record ID
    public ID accountIDValue          {get;set;} //Used for account billing preview
    public Decimal zuoraAccountCreditBalance  {get;set;}
    public Boolean isShowPendingCancellationMsg {get;set;}
    public Boolean isShowPendingActivationMsg {get;set;}
    public Boolean isShowMessages       {get;set;}
    public String subTermType                           {get; set;}
    public Zuora__Subscription__c pendingSub {get;set;}
    
    //parameters used to show billing preview after quote is sent to zbilling 
    //because the subscription record is not yet synced 
    public String zuoraSubscriptionIDValue    {get;set;}
    public String productRatePlanIDValue    {get;set;}
    public Date   subscriptionStartDateValue  {get;set;}
    
    //the List of invoice items to show on the UI
    public List<Zuora_BillingPreviewInvoiceItems> lstInvoiceItems{
      get{
        
        //if the List invoice is null call the load billing preview details
        if(lstInvoiceItems==null){
          loadBillingPreviewDetails();
        }
        
        return lstInvoiceItems;
      }
      private set;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/12/2015
    Function    get the total invoice amount value
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
  public Decimal gettotalInvoices(){
      Decimal totalInvoiceAmount=0;
      for(Zuora_BillingPreviewInvoiceItems invoiceItem : lstInvoiceItems){
        totalInvoiceAmount+=invoiceItem.invoiceItemAmount;
      }
      return totalInvoiceAmount;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/12/2015
    Function    this is the constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul   1.1     25/2/2016 remove the totalInvoices 
    ****************************************************************************************/
  public Zuora_QuoteBillingPreviewController() {
    isShowPendingCancellationMsg=false;
    isShowPendingActivationMsg=false;
    isShowMessages = true;
      isMonthly = false;
  }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/12/2015
    Function    this function is called to load the billing preview details of the quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         15/02/2016
    Sally ElGhoul   1.2     25/2/2016 use Zuora_BillingPreviewInvoiceItems for invoices
    ****************************************************************************************/
    public pageReference loadBillingPreviewDetails(){
      try{
        
        if(!Test.isRunningTest()){zApiInstance.zlogin();}
        
        //initialize the invoice items List
          lstInvoiceItems=new List<Zuora_BillingPreviewInvoiceItems>();
          List<Zuora.zObject> lstBillingDetails=new List<Zuora.zObject>();
        
        //get the billing preview of the quot
        if(quoteIDValue!=null){
          lstBillingDetails=getQuoteBillingPreviewDetails();
        }else if(subscriptionIDValue!=null){ //get the billing preview of the subscriptoon by creating a fake amendment with zero pounds discount
          lstBillingDetails=GetSubscriptionBillingPreviewDetails();
        }else if(accountIDValue!=null && zuoraSubscriptionIDValue ==null){//get the billing preview of the account's subscription
          lstBillingDetails=GetAccountBillingPreviewDetails();
        }else if(zuoraSubscriptionIDValue!=null && productRatePlanIDValue!=null && subscriptionStartDateValue!=null){
          setIsMonthly(subTermType);
          accountId = accountIDValue;
          lstBillingDetails=Zuora_BillingPreviewUtility.previewSubscriptionBillingDetails(zApiInstance,zuoraSubscriptionIDValue,productRatePlanIDValue,subscriptionStartDateValue);
        }
        
        //get the zuora account credit balance
        system.debug('check isCalculateCreditBalance: '+isCalculateCreditBalance);
        if(accountId!=null && isCalculateCreditBalance){
          zuoraAccountCreditBalance=getAccountCreditBalance();
          system.debug('check zuoraAccountCreditBalance: '+zuoraAccountCreditBalance);
        }
        
        //fill the invoice items List
        //lstBillingDetails can be null if the invoiceData return from Zuora is null
        if(lstBillingDetails!=null && lstBillingDetails.size()>0){
          lstInvoiceItems=Zuora_BillingPreviewUtility.fillInvoiceItemsList(lstBillingDetails,isMonthly,isCalculateCreditBalance,zuoraAccountCreditBalance);
        }
        
      }catch(TMGUtil.GenericException genericExceptionObj){system.debug('Generic Error Occured loadBillingPreviewDetails(): '+genericExceptionObj);ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getMessage());ApexPages.addMessage(myMsg);}catch(exception ex){system.debug('Error Occured loadBillingPreviewDetails(): '+ex+' Line: '+ex.getLineNumber());ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,Label.New_Digital_Platform_Generic_Error_Message);ApexPages.addMessage(myMsg);}
      
      return null;
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        1/02/2016
    Function    this function is called to get the billing preview details of the quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         12/02/2016   - added setIsMonthly invocation 
    ****************************************************************************************/
    private List<Zuora.zObject> getQuoteBillingPreviewDetails(){
      
      List<Zuora.zObject> lstBillingDetails=new List<Zuora.zObject>();
        
      //get the quote record
    this.quoteObj=ZuoraQuote_Utility.getQuoteRecord(quoteIDValue);
    if(quoteObj!=null){
      //fill the account Id to use it to get the account's credit balance
      accountId=quoteObj.zqu__Account__c;
    
      if(quoteObj.zqu__SubscriptionType__c==Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE){
          //new subscription, call the zsubscribe
          lstBillingDetails=Zuora_BillingPreviewUtility.previewNewSubBillingDetails(zApiInstance,quoteObj);
        }else if(quoteObj.zqu__SubscriptionType__c==Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE){
          //amendment, call the zamend
          lstBillingDetails=Zuora_BillingPreviewUtility.previewAmendmentBillingDetails(zApiInstance,quoteObj);
        }
        setIsMonthly(quoteObj.Subscription_Rate_Plan_Term_Type__c);
    }

      return lstBillingDetails; 
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        1/02/2016
    Function    this function is called to get the billing preview details of the subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         12/02/2016   - added setIsMonthly invocation 
    Sally ElGhoul     1.2     15/2/2016 - Passing Subscription Service activation Date to billing preview instead of the start Date so I need to query it while getting subscription
    Michal Szewczyk   1.3     31/08/2016 - Added pendingSub to show it on the page 
    ****************************************************************************************/
    private List<Zuora.zObject> GetSubscriptionBillingPreviewDetails(){
        
      List<Zuora.zObject> lstBillingDetails=new List<Zuora.zObject>();
      
      //get the subscription ID that we are amending
        //we will show billing preview for only active , pending activation, pending cancellation subscription
        List<Zuora__Subscription__c> lstSubscription=[select Zuora__Status__c,Zuora__ServiceActivationDate__c,Zuora__SubscriptionStartDate__c,Id,Zuora__Account__c,Zuora__Zuora_Id__c,Subscription_Rate_Plan_Term_Type__c,Name
                                  from Zuora__Subscription__c
                                  where Id=:subscriptionIDValue
                                  and ((Zuora__Status__c=:Constants.SUBSCRIPTION_ACTIVE_STATUS) 
                                        OR (Zuora__Status__c=:Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS) 
                                        OR (Zuora__Status__c=:Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS))];
              
        if(lstSubscription!=null && lstSubscription.size()>0){
         
         //billing preview is not available for pending cancellation subscriptions
         if(lstSubscription[0].Zuora__Status__c==Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS){
           isShowPendingCancellationMsg=true;
           return lstBillingDetails;
         }
          //set the account Id to get the credit balance amount
          accountId=lstSubscription[0].Zuora__Account__c;      
          
          //get the billing details                                                                            
        lstBillingDetails=Zuora_BillingPreviewUtility.previewSubscriptionBillingDetails(zApiInstance,lstSubscription[0]);
        setIsMonthly(lstSubscription[0].Subscription_Rate_Plan_Term_Type__c);
        }
      return lstBillingDetails;
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        1/02/2016
    Function    this function is called to get the billing preview details of the account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         12/02/2016   - added setIsMonthly invocation
    Sally ElGhoul     1.2     15/2/2016 - Passing Subscription Service activation Date to billing preview instead of the start Date so I need to query it while getting subscription
    Michal Szewczyk   1.3     31/08/2016 - Added pendingSub to show it on the page 
    ****************************************************************************************/
    private List<Zuora.zObject> GetAccountBillingPreviewDetails(){
      List<Zuora.zObject> lstBillingDetails=new List<Zuora.zObject>();
      //set the account Id value to use it while getting the account credit balance
      accountId=accountIDValue;
      
      //get the subscription ID that we are amending
      //we will show billing preview for only active , pending activation, pending cancellation subscription
        List<Zuora__Subscription__c> lstSubscription=[select Zuora__Status__c,Zuora__SubscriptionStartDate__c,Zuora__ServiceActivationDate__c,Id,Zuora__Account__c,Zuora__Zuora_Id__c,Subscription_Rate_Plan_Term_Type__c,Name
                                  from Zuora__Subscription__c 
                                  where Zuora__Account__c=:accountId 
                                    and ((Zuora__Status__c=:Constants.SUBSCRIPTION_ACTIVE_STATUS) 
                                        OR (Zuora__Status__c=:Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS) 
                                        OR (Zuora__Status__c=:Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS))];
          
        if(lstSubscription!=null && lstSubscription.size()>0){      
        
          //billing preview is not available for pending cancellation subscriptions
          for(Zuora__Subscription__c sub :lstSubscription ) {

            if(sub.Zuora__Status__c==Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS){
               isShowPendingCancellationMsg=true;
            }
            if(sub.Zuora__Status__c==Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS){
               isShowPendingActivationMsg=true;
               pendingSub = sub;
            }
          }

          if(isShowPendingCancellationMsg || isShowPendingActivationMsg) {
             return lstBillingDetails;
          }

          lstBillingDetails=Zuora_BillingPreviewUtility.previewSubscriptionBillingDetails(zApiInstance,lstSubscription[0]);
          setIsMonthly(lstSubscription[0].Subscription_Rate_Plan_Term_Type__c);
        }
        
      return lstBillingDetails;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        05/01/2016
    Function    this function is called to get the account credit balance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul                   1/2/2016
    ****************************************************************************************/
    private Decimal getAccountCreditBalance(){
      
      Decimal accountBalance=0;
      
      //get the zuora account to get the credit balance
      List <Zuora.zObject> lstZuoraAccount=Zuora_Utility.getZuoraBillingAccounts(zApiInstance,accountId);
      
      system.debug('check lstZuoraAccount: '+lstZuoraAccount);
      
      //if the zuora account List is not empty and the zuora account if found
      if(lstZuoraAccount!=null && lstZuoraAccount.size()>0){
        
        //get the account credit balance if not empty and if it is > zero
        if(lstZuoraAccount[0].getValue('CreditBalance')!=null && ((Decimal)lstZuoraAccount[0].getValue('CreditBalance'))>0){
          accountBalance=(Decimal)lstZuoraAccount[0].getValue('CreditBalance');
        }
      }
      system.debug('check accountBalance: '+accountBalance);
      return accountBalance;
    }
    /*************************************************************************************** 
    Developer   Michal Szewczyk 
    Date        12/02/2016
    Function    this function is called to set type of sub 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void setIsMonthly(String subType){

        if(subType == Constants.RATE_PLAN_MONTHLY) {
          this.isMonthly = true;
        } else {
          this.isMonthly = false;
        }
    }
}