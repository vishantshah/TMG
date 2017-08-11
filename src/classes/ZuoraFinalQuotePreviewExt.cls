/**
* Author:       Sally ElGhoul (Accenture)
* Date:         26/10/2015
* Description:  this class is the extension to page ZuoraFinalQuotePreview
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      13/01/2016
**/
public class ZuoraFinalQuotePreviewExt extends zqu.QuotePreviewController {

  /*INSTANCE VARIABLES*/
  // Configuration options for quote preview component
  public zqu.QuotePreviewOptions previewOptions {
    get;
    set;
  }
  // Configuration options for notification component within quote preview component
  public zqu.NotificationOptions notificationOptions {
    get;
    set;
  }
  // Handler to the quote object
  public zqu__Quote__c quote {
    get;
    set;
  }

  public string PaymentMethodId {get; set;}
  public Zuora.zApi api {get; set;}
  public boolean isShowBillingPreview {get; set;}
  public zqu__Quote__c metricsQuote   {get; set;}

  /***************************************************************************************
  Developer   Sally ElGhoul (Accenture)
  Date        27/10/2015
  Function    constructor
  ******************* Change Log *******************
  Modified by         Version     Change Date
  Michal Kwika         1.1           13/01/2016
  ****************************************************************************************/
  public ZuoraFinalQuotePreviewExt(ApexPages.StandardController stdController) {

    //hide initially the billing preview till the update quote metrics is done
    isShowBillingPreview = false;

    // Get quote object
    quote = (zqu__Quote__c) stdController.getRecord();
    //assign the same quote to metricQuote
    metricsQuote = ZuoraQuote_Utility.getQuoteRecord(stdController.getId());
    //zuora api login
    api = new Zuora.zApi();
    if ( !Test.isRunningTest() ) {api.zlogin();}

    //get the payment method id
    PaymentMethodId = ApexPages.currentPage().getParameters().get(constants.PAYMENT_METHOD_ID_QUERY_STRING);

    // Initialize preview options
    previewOptions = new zqu.QuotePreviewOptions();

    // Pass quote id to the preview options
    previewOptions.quoteId = stdController.getId();

    // Set display options
    previewOptions.buttonBarLocation = 'top';
    previewOptions.quotePropertyTitle = 'Quote Details';
    previewOptions.selectedProductsTitle = 'Selected Products and Rate Plans';
    previewOptions.isSelectedProductsCollapsible = true;

    // Set preview controller and CreateOrderPlugin
    previewOptions.previewController = this;
    //The Create Order Plugin is used to send a quote to Z-Billing. This plug-in is executed when the user clicks Submit on the Order Preview page.
    previewOptions.createOrderPlugin = 'ZuoraFinalQuotePreviewExt.CreateOrderPlugin';

    // Initialize the notification options
    notificationOptions = new zqu.NotificationOptions();

    // If the quote is missing a Bill To Contact or Sold To Contact, disable the create order button
    // and display a popup message for the error
    if (quote.zqu__BillToContact__c == null || quote.zqu__SoldToContact__c == null) {
      previewOptions.disableCreateButton = true;
      notificationOptions.failureBody = Label.Quote_Preview_Bill_To_Contact_Label_Error;
      notificationOptions.isPopup = true;
      notificationOptions.backAction = 'goToQuotePage();';
    } else if (quote.zqu__Status__c != constants.QUOTE_STATUS_NEW_VALUE) { //if the quote status is not new throw an exception
      previewOptions.disableCreateButton = true;
      notificationOptions.failureBody = Label.Quote_Preview_Status_Error;
      notificationOptions.isPopup = true;
      notificationOptions.backAction = 'goToAccountPage();';
    }

    // Set configuration options for notification component within quote preview component
    previewOptions.notificationOptions = notificationOptions;
  }

  /***************************************************************************************
  Developer   Sally ElGhoul (Accenture)
  Date        27/10/2015
  Function    Update the quote metrics if the default offer code is added
  ******************* Change Log *******************
  Modified by         Version     Change Date
  Michal Kwika        1.1         13/01/2016
  ****************************************************************************************/
  public void updateQuoteMetrics() {

    if (ApexPages.currentPage().getParameters().containsKey(constants.REFERESH_QUOTE_METRICS_QUERY_STRING)) {
      if (boolean.valueof(ApexPages.currentPage().getParameters().get(constants.REFERESH_QUOTE_METRICS_QUERY_STRING)) == true) {
        list<zqu__Quote__c> lstQuotes = [select id, zqu__Previewed_Discount__c, zqu__Previewed_Total__c, zqu__Previewed_Tax__c, zqu__Previewed_MRR__c, zqu__Previewed_TCV__c, zqu__Previewed_SubTotal__c from zqu__Quote__c where id = :quote.id];

        if (lstQuotes != null && lstQuotes.size() > 0) {
          system.debug('check before preview quote page');
          List < zqu.zQuoteUtil.zBillingResult > results = zqu.zQuoteUtil.previewQuotes(new list<id> {quote.id});
          for (zqu.zQuoteUtil.zBillingResult result : results) {
            if (result.success) {
              lstQuotes[0].zqu__Previewed_Discount__c = result.totalInfo.discount;
              lstQuotes[0].zqu__Previewed_Tax__c    = result.totalInfo.tax;
              lstQuotes[0].zqu__Previewed_Total__c    = result.totalInfo.total;

              //assign to metricQuote
              metricsQuote.zqu__Previewed_Discount__c = result.totalInfo.discount;
              metricsQuote.zqu__Previewed_Tax__c    = result.totalInfo.tax;
              metricsQuote.zqu__Previewed_Total__c    = result.totalInfo.total;
              metricsQuote.zqu__Previewed_MRR__c    = lstQuotes[0].zqu__Previewed_MRR__c;
              metricsQuote.zqu__Previewed_TCV__c    = lstQuotes[0].zqu__Previewed_TCV__c;
              metricsQuote.zqu__Previewed_SubTotal__c    = lstQuotes[0].zqu__Previewed_SubTotal__c;

              System.debug('### MetricsQuote: ' +metricsQuote);
            }
          }
          update lstQuotes;
        }
      }
    }
  }

  public void ShowBillingPreview() {
    isShowBillingPreview = true;
  }

  /***************************************************************************************
  Developer   Sally ElGhoul (Accenture)
  Date        27/10/2015
  Function    Method to return to quote's detail page from notification popup
  ******************* Change Log *******************
  Modified by         Version     Change Date
  ****************************************************************************************/
  public PageReference goToQuotePage() {
    return new PageReference('/' + quote.Id);
  }

  /***************************************************************************************
  Developer   Sally ElGhoul (Accenture)
  Date        27/10/2015
  Function    Return a page reference to the next page to be navigated to
  ******************* Change Log *******************
  Modified by         Version     Change Date
  ****************************************************************************************/
  public PageReference goToAccountPage() {
    return new PageReference('/' + quote.zqu__Account__c);
  }

  /***************************************************************************************
  Developer   Sally ElGhoul (Accenture)
  Date        27/10/2015
  Class    Plugin implementation of ICreateOrder interface
  ******************* Change Log *******************
  Modified by         Version     Change Date
  ****************************************************************************************/
  public class CreateOrderPlugin implements ICreateOrderPlugin {
    public PageReference CreateOrder(zqu.QuotePreviewController qpc) {

      List <Zuora.zObject> lstZuoraBillingAccounts = new List <Zuora.zObject>();
      string zuoraBillingAccountId = '';
      map<boolean, string> mapResultStatusMessage = new map<boolean, string>();

      // Cast plugin instance
      ZuoraFinalQuotePreviewExt previewController = (ZuoraFinalQuotePreviewExt) qpc;

      //Retrieve quote object from outer controller
      zqu__Quote__c quote = previewController.quote;
      if (quote == null) return null;

      //check if the billing account is created in zuora by core api or no
      lstZuoraBillingAccounts = Zuora_Utility.getZuoraBillingAccounts(previewController.api, quote.zqu__Account__c);

      if (lstZuoraBillingAccounts != null && lstZuoraBillingAccounts.size() > 0) {
        //Zbilling account already exist in Zuora for this account
        zuoraBillingAccountId = (string)lstZuoraBillingAccounts[0].getvalue('Id');
        system.debug('Check .... Zbilling account already Exist');
      } else {
        //if zbilling account doesn't exist in zuora, create the zbilling account and its contact first in Zbilling then use it to call send to zbilling
        zuoraBillingAccountId = Zuora_Utility.CreateZuoraBillingAccount(previewController.api, quote.zqu__Account__c);
        system.debug('Check .... Zbilling account Created by Salesforce');
      }

      if (!string.isempty(zuoraBillingAccountId)) {
        //4.in case of existing account, we have to update the account itself to set the auto pay to true and set the payment method to the default payment method for the account
        if (!string.isempty(previewController.PaymentMethodId)) {
          Zuora_Utility.setDefaultPaymentMethod(previewController.api, zuoraBillingAccountId, previewController.PaymentMethodId, true);
        }

        //call the custom call to send to zbilling
        if ( !Test.isRunningTest() ) {
          mapResultStatusMessage = Zuora_Utility.sendQuoteToZBilling(quote.id, quote.zqu__Account__c, zuoraBillingAccountId, previewController.PaymentMethodId);
        } else {
          mapResultStatusMessage = new map<boolean, string>();
          mapResultStatusMessage.put(true, 'Done');
        }

        handleSendtoZbillingResult(mapResultStatusMessage, previewController);
      } else {
        throw new TMGUtil.GenericException('Zuora account Not found for this Salesforce account... Please contact your administrator');
      }
      //Stay on current page
      return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        14/07/2015
    Function    this function is called to
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         11/01/2016
    ****************************************************************************************/
    public void handleSendtoZbillingResult(map<boolean, string> mapResultStatusMessage, zqu.QuotePreviewController qpc) {

      // Cast plugin instance
      ZuoraFinalQuotePreviewExt previewController = (ZuoraFinalQuotePreviewExt) qpc;

      //Display results using popup notification component
      previewController.notificationOptions.isPopup = true;

      for (boolean isSuccessValue : mapResultStatusMessage.keyset()) {
        if (isSuccessValue) {
          //hadle the notification settings
          previewController.notificationOptions.continueLabel  = constants.ZUORA_OK_BUTTON_TEXT;
          previewController.notificationOptions.backAction     = '';
          previewController.notificationOptions.continueAction = 'goToAccountPage();';

          //add the message
          string successMessage = constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE;
          if (!string.isempty(mapResultStatusMessage.get(isSuccessValue))) {
            successMessage = mapResultStatusMessage.get(isSuccessValue);
          }
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMessage));
          //another prompts for agent
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_SUB_SETUP));
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_ACCESS));
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_REVIEW));
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Constants.ZUORA_SEND_TO_ZBILLING_SUCCESS_MESSAGE_THANK));
        } else {
          //hadle the notification settings
          previewController.notificationOptions.backAction = 'goToQuotePage();';

          //add the message
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, mapResultStatusMessage.get(isSuccessValue)));
        }
      }
    }
  }

}