/**
* Author:       Sally ElGhoul (Tquila)
* Date:         29/06/2015
* Description:  this class is controller to the page Zuora_sendToZBilling
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      04/02/2016 - added redirection to summary page. Removed some messages
* Wiktor Czykin     22/09/2016 - modified ... a bit. I added passing of subscription id from zuora response as parameter to the summary page.
* Wiktor Czykin     17/05/2017 - modified sendToZbilling()
**/
public class Zuora_sendToZBillingController {

    private Zuora.zApi api = new Zuora.zApi();
    public zqu.NotificationOptions notificationOptions {get;set;}
    public static final String strGracePeriodDuration=Application_Settings__c.getInstance(Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME).value__c;
    private String subscriptionId;
    private String accountId;
    private String quoteId;

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         22/09/2016  //moved here parameters fetching
    ****************************************************************************************/
    public Zuora_sendToZBillingController(){
        notificationOptions = new zqu.NotificationOptions();
        notificationOptions.isPopup = true;
        notificationOptions.backAction = 'goToQuotePage();';
        validateQueryStrings();
        accountId = ApexPages.currentPage().getParameters().get(Constants.SF_ACCOUNT_ID_QUERY_STRING);
        quoteId = ApexPages.currentPage().getParameters().get(Constants.QUOTE_ID_QUERY_STRING);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        29/06/2015
    Function    this function is the action function that will happen on page load and will send the quote to zbilling
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1            04/02/2016 - redirecting user to summary page if success
    Wiktor Czykin       1.2            22/09/2016 - modified sendQuoteToZBilling() methor version call
    Wiktor Czykin       1.3            17/05/2017 - replaced constant with label
    ****************************************************************************************/
    public PageReference sendToZbilling(){
        String zuoraBillingAccountId='';
        try{
            List <Zuora.zObject> lstZuoraBillingAccounts = new List <Zuora.zObject>();
            Map<Boolean, String> mapResultStatusMessage = new Map<Boolean, String>();
            if (!Test.isRunningTest()) api.zlogin();

            //get the billing account in zuora using the salesforce account id
            //check if the billing account is created in zuora by core api or no
            if (!Test.isRunningTest()) lstZuoraBillingAccounts = Zuora_Utility.getZuoraBillingAccounts(api, this.accountId);

            String resultString='';
            if(lstZuoraBillingAccounts != null && lstZuoraBillingAccounts.size()>0){
                //Zbilling account already exist in Zuora for this account
                zuoraBillingAccountId = Test.isRunningTest() ? zuoraBillingAccountId = 'testId' : (String)lstZuoraBillingAccounts[0].getvalue('Id');
            }else{
                //if zbilling account doesn't exist in zuora, create the zbilling account and its contact first in Zbilling then use it to call send to zbilling
                zuoraBillingAccountId = Test.isRunningTest() ? zuoraBillingAccountId = 'testId' : Zuora_Utility.CreateZuoraBillingAccount(api, this.accountId);
            }
            if(!String.isEmpty(zuoraBillingAccountId)){
                //4.in case of existing account, we have to update the account itself to set the auto pay to true and set the payment method to the default payment method for the account
                String paymentMethodId = ApexPages.currentPage().getParameters().get(Constants.PAYMENT_METHOD_ID_QUERY_STRING);
                if(!String.isEmpty(paymentMethodId) && !Test.isRunningTest()){
                    Zuora_Utility.setDefaultPaymentMethod(api, zuoraBillingAccountId, paymentMethodId, true);
                }
                List<zqu.zQuoteUtil.zBillingResult> lstFullResult = new List<zqu.zQuoteUtil.zBillingResult>();
                //call the custom call to send to zbilling
                if(!Test.isRunningTest()){
                    mapResultStatusMessage = Zuora_Utility.sendQuoteToZBilling(this.quoteId, this.accountId, zuoraBillingAccountId, ApexPages.currentPage().getParameters().get(Constants.PAYMENT_METHOD_ID_QUERY_STRING), lstFullResult);
                }else{
                    mapResultStatusMessage = new Map<Boolean, String>{true => 'Done'};
                }
                handleSendtoZbillingResult(mapResultStatusMessage, lstFullResult);
                return goToSummaryPage();
            }else{
                throw new TMGUtil.GenericException('Zuora account not found for this Salesforce account... Please contact your administrator');
            }
        }catch (Zuora.zAPIException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }catch(TMGUtil.GenericException genericExceptionObj){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, genericExceptionObj.getMessage()));
        }catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error));
        }
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        29/06/2015
    Function    this function is used to validate that we are passing the needed query strings
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Boolean validateQueryStrings(){
        if(!ApexPages.currentPage().getParameters().containsKey(Constants.SF_ACCOUNT_ID_QUERY_STRING) || !ApexPages.currentPage().getParameters().containskey(Constants.PAYMENT_METHOD_ID_QUERY_STRING) || !ApexPages.currentPage().getParameters().containsKey(Constants.QUOTE_ID_QUERY_STRING)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Constants.ZUORA_ZBILLING_MISSING_QUERY_STRING_ERROR_MESSAGE));
        }
        return true;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        14/07/2015
    Function    this function is called to
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         22/09/2016  //added check for zSubscriptionId in sendToZBilling response
    ****************************************************************************************/
    @TestVisible
    private void handleSendtoZbillingResult(Map<Boolean, String> mapResultStatusMessage, List<zqu.zQuoteUtil.zBillingResult> lstResults){
        if(mapResultStatusMessage.containsKey(true)){
            //hadle the notification settings
            notificationOptions.continueLabel  = Constants.ZUORA_OK_BUTTON_TEXT;
            notificationOptions.backAction     = '';
            notificationOptions.continueAction = 'goToSummaryPage();';

            if(lstResults != null && String.isNotBlank(this.quoteId)){
                for(zqu.zQuoteUtil.zBillingResult result : lstResults){
                    if(result.success && this.quoteId == result.sfdcQuoteId && String.isNotBlank(result.zSubscriptionId)){
                        this.subscriptionId = result.zSubscriptionId;
                    }
                }
            }

            String successMessage = Constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE;
            if(String.isNotEmpty(mapResultStatusMessage.get(true))){
                successMessage = mapResultStatusMessage.get(true);
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMessage));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_THANK));
        }
        if(mapResultStatusMessage.containsKey(false)){
            notificationOptions.backAction = 'goToQuotePage();';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, mapResultStatusMessage.get(false)));
        }
    }

    /*Apex methods to expose as javascript through actionFunctions*/
    //Return a page reference to the next page to be navigated to
    public PageReference goToQuotePage() {
        return new PageReference('/'+ApexPages.currentPage().getParameters().get(Constants.QUOTE_ID_QUERY_STRING));
    }

    //Return a page reference to the next page to be navigated to
    public PageReference goToAccountPage() {
        return new PageReference('/'+ApexPages.currentPage().getParameters().get(Constants.SF_ACCOUNT_ID_QUERY_STRING));
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        04/02/2016
    Function    this function is called to redirect user to summary page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         22/09/2016 //added extra zuora subscription parameter
    ****************************************************************************************/
    public PageReference goToSummaryPage() {
        PageReference pr = Page.Zuora_SubscriptionSummary;
        pr.getParameters().put(Constants.QUOTE_ID_QUERY_STRING, ApexPages.currentPage().getParameters().get(Constants.QUOTE_ID_QUERY_STRING));
        if(String.isNotBlank(this.subscriptionId)){
            pr.getParameters().put(Constants.SUBSCRIPTION_ID_QUERY_STRING, this.subscriptionId);
        }
        return pr;
      }
}
