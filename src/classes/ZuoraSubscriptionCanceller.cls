/**
* @author Kevin Fabregue - Zuora UK
* @date unknown
* @description  Class for Zuora Subscription cancellation
#############Change Log#############
Modified by         Change Date
Pawel Chrzanowski   12/04/2016  //added method for new flow with migrated Subscriptions
Gavin Palmer        17/06/2016  // added property sfSubscriptionId
Mantas Grigaliunas  28/06/2016  //modified grace period related code
Mantas Grigaliunas  29/06/2016  //added test related variables and logic
Mantas Grigaliunas  29/03/2017  //refactored class
Mantas Grigaliunas  07/07/2017  //bug fix do handle multiple payments refund on a single invoice
**/
public with sharing class ZuoraSubscriptionCanceller {

    public static String errorMessage = '';
    public static Boolean lastPaymentCancelled = false;

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        12/04/2016
    Function    method checking Subscription information needed for hard cancellation
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.0         29/06/2016  //added test scenario for zuora call
    Mantas Grigaliunas  1.2         26/04/2017  //refactored method
    ****************************************************************************************/
    public static Boolean checkZuoraSubscriptionHasInvoices(Zuora.zApi zApi, String zuoraSubscriptionNumber){

        try{
            //check if Subscription has invoices
            String query = 'SELECT Id FROM InvoiceItem WHERE SubscriptionNumber = \'' + zuoraSubscriptionNumber + '\' ';
            List<Zuora.zObject> invoiceItemsList = new List<Zuora.zObject>();
            invoiceItemsList = ZuoraUtilities.queryToZuora(zApi, query);
            return invoiceItemsList.size() > 0;

        }catch(Exception e){
            errorMessage += e.getMessage();
            return false;
        }
    }

    /************************************************************************************
    Method Name   : checkZuoraSubscriptionEligibleCancellation
    Refactored by : Mantas Grigaliunas
    Created Date  : 21/04/2017
    Function      : Method to check if subscription  is eligible for cancellation
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Boolean checkZuoraSubscriptionEligibleCancellation(Zuora.zApi zApi, String zAccountNumber, String subscriptionNumber, String subscriptionId, String sfStatus, String sfZuoraStatus){
        if(!isSubscriptionActive(zApi, subscriptionNumber, sfStatus, sfZuoraStatus)){ return false; }
        if(!isRefundAllowed(subscriptionId)){ return false; }
        if(!isAccountBalanceZero(zApi, zAccountNumber)){ return false; }
        return true;
    }

    /************************************************************************************
    Method Name   : isSubscriptionActive
    Refactored by : Mantas Grigaliunas
    Created Date  : 21/04/2017
    Function      : Method to check if subscription is active
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Boolean isSubscriptionActive(Zuora.zApi zApi, String subscriptionNumber, String sfStatus, String sfZuoraStatus) {

        try{
            String subscriptionQuery = 'SELECT Id, AccountId, SubscriptionStartDate, TermEndDate FROM Subscription WHERE ';
            subscriptionQuery += 'Name = \'' + subscriptionNumber + '\' AND Status = \'' + Constants.SUBSCRIPTION_STATUS_ACTIVE_VALUE + '\'';
            
            List<Zuora.zObject> subscriptionList = new List<Zuora.zObject>();
            subscriptionList = ZuoraUtilities.queryToZuora(zApi, subscriptionQuery);
            if((sfStatus == Constants.SUBSCRIPTION_ACTIVE_STATUS || sfStatus == Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS) 
                && sfZuoraStatus == Constants.SUBSCRIPTION_ACTIVE_STATUS && subscriptionList.size() == 1){
                    return true; 
            } else if(subscriptionList.size() == 0 && (sfZuoraStatus == Constants.SUBSCRIPTION_ACTIVE_STATUS || sfStatus == Constants.SUBSCRIPTION_ACTIVE_STATUS)){
                errorMessage += Label.Zuora_Subscription_Canceller_Inactive_On_Zuora;
                return false;
            } else if(subscriptionList.size() == 1 && (sfZuoraStatus == Constants.SUBSCRIPTION_CANCELLED_STATUS
                || sfStatus == Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS 
                || sfStatus == Constants.SUBSCRIPTION_CANCELLED_STATUS)){
                errorMessage += Label.Zuora_Subscription_Canceller_Active_On_Zuora;
                return false;
            } else{
                errorMessage += Label.Zuora_Subscription_Cancellation_Already_Cancelled_Error_Message;
                return false;
            }
        }catch(Exception e){
            errorMessage += e.getMessage();
            return false;
        }
    }

    /************************************************************************************
    Method Name   : isAccountBalanceZero
    Refactored by : Mantas Grigaliunas
    Created Date  : 21/04/2017
    Function      : Method to check if Zuora subscription has any outstanding balances
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Boolean isAccountBalanceZero(Zuora.zApi zApi, String zAccountNumber) {

        try{
            Boolean isAccountBalanceZero = true;

            String accountQuery = 'SELECT Id, TotalInvoiceBalance, Balance, CreditBalance FROM Account WHERE AccountNumber = \'' + zAccountNumber + '\'';

            List<Zuora.zObject>  zAccountList = new List<Zuora.zObject>();
            if(!Test.isRunningTest()){
                zAccountList = ZuoraUtilities.queryToZuora(zApi, accountQuery);
            } else {
                zAccountList = Z_TestFactory.createZuoraAccounts();
            }

            if ((Decimal) zAccountList.get(0).getValue('TotalInvoiceBalance') != 0) {
                errorMessage += 'The Invoice balance is NOT 0.';
                isAccountBalanceZero = false;
            }
            if ((Decimal) zAccountList.get(0).getValue('Balance') != 0) {
                errorMessage += 'The Account balance is NOT 0.';
                isAccountBalanceZero = false;
            }
            if ((Decimal) zAccountList.get(0).getValue('CreditBalance') != 0) {
                errorMessage += 'The Credit balance is NOT 0.';
                isAccountBalanceZero = false;
            }
            return isAccountBalanceZero;

        }catch(Exception e){
            errorMessage += e.getMessage();
            return false;
        }
    }

    /************************************************************************************
    Method Name   : isSubscriptionInGracePeriod
    Refactored by : Mantas Grigaliunas
    Created Date  : 21/04/2017
    Function      : Method to check if subscription is in grace period
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Boolean isSubscriptionInGracePeriod(Date subscriptionStartDate, String strGracePeriodDuration){

        try{
            if(String.isBlank(strGracePeriodDuration)){
                List<String> labelParameter = new List<String>{Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME};
                errorMessage += String.format(Label.Zuora_Subscription_Canceller_Grace_Period_Not_Set_Error, labelParameter);
                return false;
            } 
            else if (Date.today() <= subscriptionStartDate.addDays(Integer.valueof(strGracePeriodDuration))) return true;
            else return false;
        }catch(Exception e){
            errorMessage += e.getMessage();
            return false;
        }
    }

    /************************************************************************************
    Method Name   : isRefundAllowed
    Refactored by : Mantas Grigaliunas
    Created Date  : 21/04/2017
    Function      : Method to check if refund is allowed for specific product
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Boolean isRefundAllowed(String subscriptionId){

        try{

            List<Zuora__SubscriptionProductCharge__c> productCharge = [SELECT Id, Zuora__Product__r.Zuora__External_Id__c FROM Zuora__SubscriptionProductCharge__c 
                                                                       WHERE Zuora__Subscription__c = :subscriptionId LIMIT 1 ];
            if(productCharge.isEmpty()){
                errorMessage = Label.Zuora_Subscription_Canceller_Charge_Product_Not_Found;
                return false;
            }

            String zuoraId = productCharge.get(0).Zuora__Product__r.Zuora__External_Id__c;
            if(String.isBlank(zuoraId)){
                errorMessage = Label.Zuora_Subscription_Canceller_Prduct_Zuora_Id_Blank;
                return false;
            }

            List<zqu__ZProduct__c> zProduct = [SELECT Id, Name, RefundsAllowed__c FROM zqu__ZProduct__c WHERE zqu__ZuoraId__c = :zuoraId LIMIT 1 ];
            if(zProduct.isEmpty()){
                errorMessage = String.format(Label.Zuora_Subscription_Canceller_ZProduct_Not_Found, new List<String>{zuoraId});
                return false;
            }
            if(zProduct.get(0).RefundsAllowed__c == 'No'){
                errorMessage = String.format(Label.Zuora_Subscription_Canceller_Cancellation_Not_Allowed, new List<String>{zProduct.get(0).Name});
                return false;
            }
            return true;

        }catch(Exception e){
            errorMessage += e.getMessage();
            return false;
        }
    }      

    /************************************************************************************
    Method Name   : processSubscriptionCancellation
    Refactored by : Mantas Grigaliunas
    Created Date  : 28/09/2016
    Function      : function to process zuora subscription cancellation
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    07/07/2017  Added code to handle multiple payments refund for a single invoice
    *************************************************************************************/
    public static Decimal processSubscriptionCancellation(Zuora.zApi zApi, String zAccountId, String zSubscriptionId, String subscriptionNumber, Date cancellationDate, 
        String  cancellationReason, String  subCancellationReason, Boolean preview, Boolean processInvoice, Boolean isProductSwitch){

        String log = TMGUtil.newZuoraWebServiceLog('processSubscriptionCancellation', 'ZuoraSubscriptionCanceller', 
            new Map<String, Object>{'zAccountId'            => zAccountId,
                                    'zSubscriptionId'       => zSubscriptionId,
                                    'subscriptionNumber'    => subscriptionNumber,
                                    'cancellationDate'      => cancellationDate,
                                    'cancellationReason'    => cancellationReason,
                                    'subCancellationReason' => subCancellationReason,
                                    'preview'               => preview,
                                    'processInvoice'        => processInvoice,
                                    'isProductSwitch'       => isProductSwitch});

        try{

            Decimal refundInvoiceAmount = 0;
            Date today = Date.today();
            Date effectiveDate = cancellationDate;
            Date serviceActivationDate = cancellationDate;
            Date invDate = today;
            Date invTargetDate = (cancellationDate > today ? cancellationDate : today);
            String amendmentCancellationReason = cancellationReason;
            if(!String.isBlank(subCancellationReason)) 
                amendmentCancellationReason += ' - ' + subCancellationReason;

            //creates cancelation amendment in Zuora
            Zuora.zApi.AmendResult amendResult = ZuoraUtilities.createCancellationAmendment(
                zApi, preview, processInvoice, zSubscriptionId, Constants.SUBSCRIPTION_TYPE_AMENDMENT_CANCELLATION_ZUORA, 
                amendmentCancellationReason, Constants.COMPLETE_CANCELLATION_STATUS, effectiveDate, serviceActivationDate, invDate, invTargetDate);       

            if(amendResult.Success && !preview){
                //log cancellation information on Zuora
                DateTime cancellationEffectiveDateTime = DateTime.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day(), 0, 0, 0);
                Zuora_Utility.UpdateCancelledSubscription(zApi, cancellationReason, subCancellationReason, String.valueOf(cancellationEffectiveDateTime), String.valueOf(DateTime.now()), amendResult.SubscriptionId);

            }else if(!amendResult.Success){

                if(amendResult.Errors != null){
                    errorMessage += ZuoraUtilities.getErrors(amendResult.Errors);
                }
                return null;
            }

            if(preview) {

                if(amendResult.InvoiceDatas != null){
                    Zuora.zObject amendInvoice = (Zuora.zObject)amendResult.InvoiceDatas.get(0).getValue('Invoice');
                    return -(Decimal)amendInvoice.getValue('Amount');
                } else {
                    return refundInvoiceAmount;
                }

            } else if(amendResult.InvoiceId != null && amendResult.SubscriptionId != null){

                //log cancellation information on Zuora
                DateTime cancellationEffectiveDateTime = DateTime.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day(), 0, 0, 0);
                Zuora_Utility.UpdateCancelledSubscription(zApi, cancellationReason, subCancellationReason, String.valueOf(cancellationEffectiveDateTime), String.valueOf(DateTime.now()), amendResult.SubscriptionId);

                String refundInvoiceId = (String) amendResult.InvoiceId;

                //get the total amount of cancelation invoice
                String invoiceQuery             = 'SELECT Id, Amount, InvoiceNumber FROM Invoice WHERE Id = \'' + refundInvoiceId + '\' ';
                List<Zuora.zObject> invoiceList = ZuoraUtilities.queryToZuora(zApi, invoiceQuery);
                refundInvoiceAmount = -((Decimal) invoiceList.get(0).getValue('Amount'));

                //process cancellation if not preview mode and there are outstanding funds available    
                if(refundInvoiceAmount > 0) {

                    if(isProductSwitch){

                        List<Zuora.zObject> transferCreditBalanceList = new List<Zuora.zObject>();
                        transferCreditBalanceList.add(ZuoraUtilities.createCreditBalanceAdjustment(refundInvoiceAmount, refundInvoiceId, Constants.ZUORA_CBA_TYPE_INCREASE));
                        
                        if(!insertZuoraObject(zApi, transferCreditBalanceList)){
                            errorMessage += Label.Zuora_Subscription_Canceller_Credit_Balance_Transfer_Failure;
                        }

                    } else{

                        Map<String, String> zInvoiceMap = new Map<String, String>();
                        ZuoraSubscriptionCancellationWrapper zscw = new ZuoraSubscriptionCancellationWrapper();
                        List<ZuoraSubscriptionCancellationWrapper> wrapperList = zscw.getZuoraSubscriptionCancellationWrapperList(
                            zApi, subscriptionNumber, refundInvoiceId, zAccountId);
                        Boolean isDirectDebitPayment = (ZuoraUtilities.getPaymentMethodType(zApi, zAccountId) == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE ? true : false);
                        Map<String, VoidedPaymentWrapper> paymentsToVoidMap = new Map<String, VoidedPaymentWrapper>();

                        //create refunds based on cancelled invoice items
                        List<Zuora.zObject> refundToCreateList = new List<Zuora.zObject>();

                        Map<String, Decimal> multiplePaymentsTotalAmountMap = new Map<String, Decimal>();

                        for(ZuoraSubscriptionCancellationWrapper wrapperItem : wrapperList){

                            String paymentId = wrapperItem.paymentId;
                            String paymentMethod = wrapperItem.paymentMethod;
                            Decimal paymentAmount = wrapperItem.paymentAmount;
                            Decimal refundAmount = wrapperItem.totalAmount;

                            //logic below required to handle multiple payments on a single invoice
                            Decimal remainingRefundAmount;
                            if(multiplePaymentsTotalAmountMap.get(wrapperItem.paymentInvoiceId) == null){
                                multiplePaymentsTotalAmountMap.put(wrapperItem.paymentInvoiceId, refundAmount);
                                remainingRefundAmount = refundAmount;
                            } else {
                                remainingRefundAmount = multiplePaymentsTotalAmountMap.get(wrapperItem.paymentInvoiceId);
                            }

                            //if expected amount is refunded ignore the rest payments for the same invoice
                            if(remainingRefundAmount <= 0) {
                                continue;
                            }
                            
                            if(paymentAmount <= remainingRefundAmount){
                                refundAmount = paymentAmount;
                            } else {
                                refundAmount = remainingRefundAmount;
                            }

                            //update remaining refund amount for the particular invoice
                            multiplePaymentsTotalAmountMap.put(wrapperItem.paymentInvoiceId, remainingRefundAmount - refundAmount);

                            if(((wrapperItem.paymentMethod != Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE && wrapperItem.gatewayState == Constants.ZUORA_PAYMENT_GATEWAY_STATE_SUBMITTED)
                                ||(wrapperItem.paymentMethod == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE && wrapperItem.gatewayState == Constants.ZUORA_PAYMENT_GATEWAY_STATE_SETTLED)) 
                                && wrapperItem.paymentType == Constants.ZUORA_REFUND_TYPE_ELECTRONIC){
                                
                                refundToCreateList.add(ZuoraUtilities.createRefund(zAccountId, refundAmount, paymentId, Constants.ZUORA_REFUND_SOURCE_TYPE_PAYMENT, Constants.ZUORA_REFUND_TYPE_ELECTRONIC));
                                zInvoiceMap.put(paymentId, wrapperItem.paymentInvoiceId);

                            } else if(wrapperItem.paymentMethod == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE && wrapperItem.gatewayState == Constants.ZUORA_PAYMENT_GATEWAY_STATE_SUBMITTED 
                                      && wrapperItem.paymentType == Constants.ZUORA_REFUND_TYPE_ELECTRONIC){

                                paymentsToVoidMap.put(paymentId, new VoidedPaymentWrapper(paymentAmount, refundAmount, wrapperItem.chargeAmount, 
                                    wrapperItem.taxAmount, wrapperItem.taxationItemId, wrapperItem.invoiceItemId, wrapperItem.paymentInvoiceId,
                                    wrapperItem.paymentInvoiceNumber));
         
                            } else if (wrapperItem.paymentType == Constants.ZUORA_REFUND_TYPE_EXTERNAL){
                                errorMessage += Label.Zuora_Subscription_Canceller_External_Payment_Error;
                                refundInvoiceAmount -= wrapperItem.totalAmount;
                            }
                        }

                        //void DD payments that are not processed yet
                        if(paymentsToVoidMap.size() > 0){
                            List<Zuora.zObject> paymentsToUpdate = new List<Zuora.zObject>();
                            for(String paymentId : paymentsToVoidMap.keySet()){
                                Zuora.zObject payment = new Zuora.zObject('Payment');
                                payment.setValue('Id', paymentId);
                                payment.setValue('Status', 'Voided');
                                paymentsToUpdate.add(payment);
                            }

                            if(updateZuoraObject(zApi, paymentsToUpdate)){
                                //check if payment was voided because it returns success response in both cases
                                if(checkIfPaymentsVoided(zApi, paymentsToVoidMap.keySet())){
                                    lastPaymentCancelled = true;
                                    refundInvoiceAmount -= adjustCreditBalanceAfterPaymentCancellation(zApi, refundInvoiceId, paymentsToVoidMap);
                                } else {
                                    errorMessage += Label.Zuora_Subscription_Canceller_Payment_Cancellation_Failed;
                                    List<Zuora.zObject> transferCreditBalanceList = new List<Zuora.zObject>();
                                    for(String paymentId : paymentsToVoidMap.keySet()){
                                        transferCreditBalanceList.add(ZuoraUtilities.createCreditBalanceAdjustment(
                                            paymentsToVoidMap.get(paymentId).refundAmount, refundInvoiceId, Constants.ZUORA_CBA_TYPE_INCREASE));
                                    } 
                                    if(!insertZuoraObject(zApi, transferCreditBalanceList)){
                                        errorMessage += Label.Zuora_Subscription_Canceller_Credit_Balance_Transfer_Failure;
                                    }
                                }

                            } else {
                                errorMessage += 'Payment void process failed with an error.';
                            }
                        }
                        //insert refunds
                        if(!refundToCreateList.isEmpty()){

                            if(!insertZuoraObject(zApi, refundToCreateList)){ 
                                return null; 
                            } else {//adjust credit balance

                                if (!insertZuoraObject(zApi, new List<Zuora.zObject>{ 
                                        ZuoraUtilities.createCreditBalanceAdjustment(
                                            refundInvoiceAmount, refundInvoiceId, Constants.ZUORA_CBA_TYPE_INCREASE)})) { 
                                    errorMessage += Label.Zuora_Subscription_Canceller_Credit_Balance_Transfer_Failure;
                                    return null; 
                                } else {
                                    //write off credit balance from refunded invoices
                                    List<Zuora.zObject> paymentInvoiceCbaList = new List<Zuora.zObject>();
                                    for(Zuora.zObject refund : refundToCreateList){
                                        paymentInvoiceCbaList.add(ZuoraUtilities.createCreditBalanceAdjustment(
                                            (Decimal)refund.getValue('Amount'),
                                            zInvoiceMap.get((String)refund.getValue('PaymentId')), Constants.ZUORA_CBA_TYPE_DECREASE));
                                    } 
                                    if (!insertZuoraObject(zApi, paymentInvoiceCbaList)) { 
                                        errorMessage += Label.Zuora_Subscription_Canceller_Credit_Balance_Transfer_Failure;
                                        return null; 
                                    }

                                }
                            }
                        }
                    }
                }
            } 
            return refundInvoiceAmount;

        }catch(Exception e){
            errorMessage += e.getMessage();
            if(!preview) TMGUtil.insertZuoraWebServiceLog(log, errorMessage, e.getStackTraceString());
            return null;
        }  
    }

    /************************************************************************************
    Method Name   : generateCancellatioMessage
    Refactored by : Mantas Grigaliunas
    Created Date  : 02/05/2017
    Function      : Function to generate Zuora cancellation message
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static String generateCancellationMessage(Decimal cancellationAmount, Boolean processInvoice, Boolean isMonthly, Boolean isFutureDate){

        String popUpText = '';
        String BR = '\r\n\r\n';

        try{
            if ((cancellationAmount != null && String.isBlank(errorMessage))) {
                popUpText = Label.Zuora_Subscription_Canceller_Successful_Cancellation + BR;
                if(cancellationAmount > 0){
                    popUpText += String.format(Label.Zuora_Subscription_Canceller_Refund_Amount, new List<String>{String.valueOf(cancellationAmount)});
                } else if (cancellationAmount == 0){
                    if(!processInvoice && isMonthly && isFutureDate){ popUpText += Label.Zuora_Subscription_Canceller_Outstanding_Future_Payments; } 
                    else { popUpText += Label.Zuora_Subscription_Canceller_No_Outstanding_Payments; }
                } else {
                    popUpText += String.format(Label.Zuora_Subscription_Canceller_Outstanding_Payment, new List<String>{String.valueOf(-cancellationAmount)})
                              + Label.Zuora_Subscription_Canceller_Contact_Zuora_Admin;
                }

                if(lastPaymentCancelled) {
                    popUpText += Label.Zuora_Subscription_Canceller_Last_Payment_Cancelled;
                }

            } else {
                 popUpText = Label.Zuora_Subscription_Canceller_Cancellation_Error + ' ' + errorMessage + BR + Label.Zuora_Subscription_Canceller_Contact_Zuora_Admin;
            }

            return popUpText;
        }catch(Exception e){
            return popUpText + e.getMessage();
        }
    }

    /************************************************************************************
    Method Name   : insertZuoraObject
    Refactored by : Mantas Grigaliunas
    Created Date  : 28/09/2016
    Function      : function to insert zuora records and return the flag
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static Boolean insertZuoraObject(Zuora.zApi zApi, List<Zuora.zObject> zObjectList){

        String log = TMGUtil.newZuoraWebServiceLog('insertZuoraObject', 'ZuoraSubscriptionCanceller',  
            new Map<String, Object>{'zObjectList' => String.valueOf(zObjectList)});

        List<String> errorsList = ZuoraUtilities.analyzeSaveResult(ZuoraUtilities.createZuoraObjects(zApi, zObjectList));
        if (!errorsList.isEmpty()) {
            errorMessage += errorsList + '.\r\n';
            TMGUtil.insertZuoraWebServiceLog(log, errorMessage);
            return false;
        } else {
            return true;
        }
    }

    /************************************************************************************
    Method Name   : updateZuoraObject
    Refactored by : Mantas Grigaliunas
    Created Date  : 28/09/2016
    Function      : function to insert zuora records and return the flag
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static Boolean updateZuoraObject(Zuora.zApi zApi, List<Zuora.zObject> zObjectList){

        String log = TMGUtil.newZuoraWebServiceLog('updateZuoraObject', 'ZuoraSubscriptionCanceller',  
            new Map<String, Object>{'zObjectList' => String.valueOf(zObjectList)});

        List<String> errorsList = ZuoraUtilities.analyzeSaveResult(ZuoraUtilities.updateZuoraObjects(zApi, zObjectList));
        if (!errorsList.isEmpty()) {
            errorMessage += errorsList + '.\r\n';
            TMGUtil.insertZuoraWebServiceLog(log, errorMessage);
            return false;
        } else {
            return true;
        }
    }

    /************************************************************************************
    Method Name   : checkIfPaymentsVoided
    Refactored by : Mantas Grigaliunas
    Created Date  : 28/09/2016
    Function      : function to insert zuora records and return the flag
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static Boolean checkIfPaymentsVoided(Zuora.zApi zApi, Set<String> paymentIdsSet){

        String log = TMGUtil.newZuoraWebServiceLog('checkIfPaymentsVoided', 'ZuoraSubscriptionCanceller',  
            new Map<String, Object>{'paymentIdsSet' => paymentIdsSet});

        try{
            String payemntsQuery = 'SELECT Id, Status FROM Payment';
            if(!Test.isRunningTest()){
                List<Zuora.zObject> paymentsList = ZuoraUtilities.queryMultipleZItems(zApi, paymentIdsSet, payemntsQuery, 'Id', new List<String>{'Status = \'Voided\''});
                return paymentsList.size() > 0;
            } else return Z_TestFactory.testPaymentVoided;

        } catch(Exception e){
            errorMessage += e.getMessage();
            TMGUtil.insertZuoraWebServiceLog(log, errorMessage, e.getStackTraceString());
            return false;
        }
    }

    private static Decimal adjustCreditBalanceAfterPaymentCancellation(Zuora.zApi zApi, String refundInvoiceId, Map<String, VoidedPaymentWrapper> paymentsToVoidMap){

        String log = TMGUtil.newZuoraWebServiceLog('adjustCreditBalanceAfterPaymentCancellation', 'ZuoraSubscriptionCanceller',  
            new Map<String, Object>{'refundInvoiceId'     => refundInvoiceId,
                                    'paymentsToVoidMap'   => paymentsToVoidMap});
    
        Decimal totalRefundAmount = 0;

        try{

            List<Zuora.zObject> voidedPaymentInvoiceCbaList = new List<Zuora.zObject>();
            List<Zuora.zObject> paymentInvoiceItemAdjustmentsList = new List<Zuora.zObject>();
            for(String paymentId : paymentsToVoidMap.keySet()){

                //adjust cancelled payment invoice items
                VoidedPaymentWrapper voidedPayment = paymentsToVoidMap.get(paymentId);
                Decimal paymentAmount = voidedPayment.paymentAmount;
                Decimal refundAmount = voidedPayment.refundAmount;
                if(paymentAmount > refundAmount){
                    Decimal adjustmentAmount = paymentAmount - refundAmount;
                    Map<Decimal, Decimal> adjustmentAmountMap = ZuoraUtilities.calculateAdjustmentValue(
                        voidedPayment.chargeAmount, voidedPayment.taxAmount, adjustmentAmount);
                    Decimal refundAdjustmentChargeAmount;
                    Decimal refundAdjustmentTaxAmount;
                    for(Decimal adjustChargeAmount : adjustmentAmountMap.keySet()){
                        refundAdjustmentChargeAmount = adjustChargeAmount;
                        refundAdjustmentTaxAmount = adjustmentAmountMap.get(adjustChargeAmount);
                    }

                    paymentInvoiceItemAdjustmentsList.add(ZuoraUtilities.createInvoiceItemAdjustment(Date.today(), refundAdjustmentChargeAmount, 
                        voidedPayment.invoiceId, voidedPayment.invoiceNumber, voidedPayment.invoiceItemId, 'InvoiceDetail', 'Charge'));

                    paymentInvoiceItemAdjustmentsList.add(ZuoraUtilities.createInvoiceItemAdjustment(Date.today(), refundAdjustmentTaxAmount, voidedPayment.invoiceId, 
                        voidedPayment.invoiceNumber, voidedPayment.taxationItemId, 'Tax', 'Charge'));
                }

                //transfer payment balance
                voidedPaymentInvoiceCbaList.add(ZuoraUtilities.createCreditBalanceAdjustment(
                    refundAmount, refundInvoiceId, Constants.ZUORA_CBA_TYPE_INCREASE));
                // balance on cancellation invoice
                voidedPaymentInvoiceCbaList.add(ZuoraUtilities.createCreditBalanceAdjustment(
                    refundAmount, voidedPayment.invoiceId, Constants.ZUORA_CBA_TYPE_DECREASE));

                totalRefundAmount += refundAmount;
            }

            if(insertZuoraObject(zApi, paymentInvoiceItemAdjustmentsList)){
                if (!insertZuoraObject(zApi, voidedPaymentInvoiceCbaList)){
                    errorMessage += Label.Zuora_Subscription_Canceller_Credit_Balance_Transfer_Failure;
                    totalRefundAmount = 0; 
                } 
            } else { 
                errorMessage += 'Credit Balance Adjustment on cancelled payment invoice failed.';
                totalRefundAmount = 0; 
            }

        }catch(Exception e){
            errorMessage += e.getMessage();
            TMGUtil.insertZuoraWebServiceLog(log, errorMessage, e.getStackTraceString());
            return null;
        }

        return totalRefundAmount;
    }

    /************************************************************************************
    Method Name   : VoidedPaymentWrapper
    Refactored by : Mantas Grigaliunas
    Created Date  : 21/04/2017
    Function      : Wrapper class to hold voided payment related information
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public class VoidedPaymentWrapper{

        Decimal paymentAmount;
        Decimal refundAmount;
        Decimal chargeAmount;
        Decimal taxAmount;
        String  taxationItemId;
        String  invoiceItemId;
        String  invoiceId;
        String  invoiceNumber;

        public VoidedPaymentWrapper(Decimal paymentAmount, Decimal refundAmount, Decimal chargeAmount, Decimal taxAmount, 
            String taxationItemId, String invoiceItemId, String  invoiceId, String  invoiceNumber){
            this.paymentAmount  = paymentAmount;
            this.refundAmount   = refundAmount;
            this.chargeAmount   = chargeAmount;
            this.taxAmount      = taxAmount;
            this.taxationItemId = taxationItemId;
            this.invoiceItemId  = invoiceItemId;
            this.invoiceId      = invoiceId;
            this.invoiceNumber  = invoiceNumber;
        }
    }
}