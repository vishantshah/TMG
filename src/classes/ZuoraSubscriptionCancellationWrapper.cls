/************************************************************************************
Class Name   : ZuoraSubscriptionCancellationWrapper
Author       : Mantas Grigaliunas
Created Date : 29/03/2017
Function     : Wrapper class that gets and holds Zuora Subscription Amendment Invoice related information which is used to to process refunds
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class ZuoraSubscriptionCancellationWrapper {

    public String  invoiceItemId;
    public Decimal totalAmount;
    public Decimal chargeAmount;
    public Decimal taxAmount;
    public String  taxationItemId;   
    public String  paymentId;
    public String  paymentInvoiceId;
    public String  paymentInvoiceNumber;
    public Decimal paymentAmount;
    public String  gatewayState;
    public String  paymentMethod;
    public String  paymentType;

    /************************************************************************************
    Method Name  : ZuoraSubscriptionCancellationWrapper constructor
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public ZuoraSubscriptionCancellationWrapper(String invoiceItemId, Decimal totalAmount, Decimal chargeAmount, Decimal taxAmount, String  taxationItemId,
        String paymentId, String paymentInvoiceId, String  paymentInvoiceNumber, Decimal paymentAmount, String gatewayState, String paymentMethod, String paymentType) {

        this.invoiceItemId        = invoiceItemId;
        this.totalAmount          = totalAmount;
        this.chargeAmount         = chargeAmount;
        this.taxAmount            = taxAmount;
        this.taxationItemId       = taxationItemId;
        this.paymentId            = paymentId;
        this.paymentInvoiceId     = paymentInvoiceId;
        this.paymentInvoiceNumber = paymentInvoiceNumber;
        this.paymentAmount        = paymentAmount;
        this.gatewayState         = gatewayState;
        this.paymentMethod        = paymentMethod;
        this.paymentType          = paymentType;
    }

    public ZuoraSubscriptionCancellationWrapper(){}

    /************************************************************************************
    Method Name  : getZuoraSubscriptionCancellationWrapperList
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : Returns wrapper list that contains Zuora Subscription Cancellation related information
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public List<ZuoraSubscriptionCancellationWrapper> getZuoraSubscriptionCancellationWrapperList(
        Zuora.zApi zApi, String subscriptionNumber, String cancellationInvoiceId, String zAccountId){

        List<ZuoraSubscriptionCancellationWrapper> wrapperList = new List<ZuoraSubscriptionCancellationWrapper>();
        Map<String, ZuoraSubscriptionCancellationWrapper> wrapperMap = new Map<String, ZuoraSubscriptionCancellationWrapper>();

        //get all invoice items related to the same subscription
        String subInvoiceItemsQuery = 'SELECT Id, InvoiceId, ChargeAmount, TaxAmount, ServiceStartDate, ServiceEndDate ' 
                                    + 'FROM InvoiceItem WHERE SubscriptionNumber = \'' + subscriptionNumber + '\'';
        List<Zuora.zObject> allInvoiceItemsList = ZuoraUtilities.queryToZuora(zApi, subInvoiceItemsQuery);

        List<Zuora.zObject> subCancellationInvoiceItemsList            = new List<Zuora.zObject>();
        List<Zuora.zObject> subInvoiceItemsList                        = new List<Zuora.zObject>();
        List<Zuora.zObject> refundDiscountChargesList                  = new List<Zuora.zObject>();
        Map<String, String> subInvoiceItemToInvoiceMap                 = new Map<String, String>();
        Map<String, List<String>> subInvoiceToPaymentIdMap             = new Map<String, List<String>>();
        Map<String, String> cancellationInvoiceItemToSubInvoiceItemMap = new Map<String, String>();
        Map<String, Zuora.zObject> paymentsMap                         = new Map<String, Zuora.zObject>();
        Map<String, String> paymentToPaymentTypeMap                    = new Map<String, String>();
        Map<String, String> paymentToPaymentMethodMap                  = new Map<String, String>();
        Map<String, String> invoiceIdToInvoiceNumberMap                = new Map<String, String>();

        Set<String> subInvoiceIdsSet = new Set<String>();

        //split invoice items into two lists
        for(Zuora.zObject invoiceItem : allInvoiceItemsList){
            String invoiceId = (String)invoiceItem.getValue('InvoiceId');
            String invoiceItemId = (String)invoiceItem.getValue('Id');
            Decimal chargeAmount = (Decimal)invoiceItem.getValue('ChargeAmount');
            if(invoiceId == cancellationInvoiceId){
                if(chargeAmount < 0){
                    subCancellationInvoiceItemsList.add(invoiceItem);
                } else {
                    refundDiscountChargesList.add(invoiceItem);
                }
            } else if(chargeAmount > 0){
                subInvoiceItemsList.add(invoiceItem);
                subInvoiceIdsSet.add(invoiceId);
                subInvoiceItemToInvoiceMap.put(invoiceItemId, invoiceId);
            }
        }

        //get invoice numbers 
        String invoiceQuery             = 'SELECT Id, InvoiceNumber FROM Invoice';
        List<Zuora.zObject> invoiceList = ZuoraUtilities.queryMultipleZItems(zApi, subInvoiceIdsSet, invoiceQuery, 'Id', null);
        for(Zuora.zObject invoice : invoiceList){
            invoiceIdToInvoiceNumberMap.put((String)invoice.getValue('Id'), (String)invoice.getValue('InvoiceNumber'));
        }

        //get origin invoiceItems map and discount charge for the periods in cancelation invoice
        for(Zuora.zObject invoiceItem : subCancellationInvoiceItemsList){

            String invoiceItemId  = (String)invoiceItem.getValue('Id');
            Date serviceStartDate = (Date)invoiceItem.getValue('ServiceStartDate');
            Date serviceEndDate   = (Date)invoiceItem.getValue('ServiceEndDate');
            Decimal chargeAmount  = (Decimal)invoiceItem.getValue('ChargeAmount');
            Decimal taxAmount     = (Decimal)invoiceItem.getValue('TaxAmount');
            Decimal totalAmount   = chargeAmount + taxAmount;

            //get discount charge amount
            for(Zuora.zObject dcInvoiceItem : refundDiscountChargesList){
                Date dcServiceStartDate = (Date)dcInvoiceItem.getValue('ServiceStartDate');
                Date dcServiceEndDate   = (Date)dcInvoiceItem.getValue('ServiceEndDate');
                Decimal dcAmount        = (Decimal)dcInvoiceItem.getValue('ChargeAmount')
                                        + (Decimal)dcInvoiceItem.getValue('TaxAmount');
                
                if(serviceStartDate == dcServiceStartDate || serviceEndDate == dcServiceEndDate){
                    totalAmount += dcAmount;
                }
            }

            //add new item to wrapper map if there is any amount to be refunded
            if(totalAmount < 0){
                ZuoraSubscriptionCancellationWrapper wrapperItem = new ZuoraSubscriptionCancellationWrapper(
                    invoiceItemId, -totalAmount, -chargeAmount, -taxAmount, '', '', '', '', 0, '', '', '');
                wrapperMap.put(invoiceItemId, wrapperItem);
            }

            //define map of invoice items to cancellation invoice items
            for(Zuora.zObject subInvoiceItem : subInvoiceItemsList){
                Date subServiceStartDate = (Date)subInvoiceItem.getValue('ServiceStartDate');
                Date subServiceEndDate   = (Date)subInvoiceItem.getValue('ServiceEndDate');
                String subInvoiceItemId  = (String)subInvoiceItem.getValue('Id');
                
                if(serviceStartDate == subServiceStartDate || serviceEndDate == subServiceEndDate){
                    cancellationInvoiceItemToSubInvoiceItemMap.put(invoiceItemId, subInvoiceItemId);
                }
            }
        }

        //get all invoice payments that relate to invoices
        String invoicePayemntsQuery             = 'SELECT Id, PaymentId, InvoiceId FROM InvoicePayment';
        List<Zuora.zObject> invoicePaymentsList = ZuoraUtilities.queryMultipleZItems(zApi, subInvoiceIdsSet, invoicePayemntsQuery, 'InvoiceId', null);

        //get payment ids set and define a map of payment id to invoice
        Set<String> paymentIdsSet = new Set<String>();
        for(Zuora.zObject invoicePayment : invoicePaymentsList){
            String invoiceId = (String)invoicePayment.getValue('InvoiceId');
            String paymentId = (String)invoicePayment.getValue('PaymentId');
            if(subInvoiceToPaymentIdMap.get(invoiceId) == null){
                subInvoiceToPaymentIdMap.put(invoiceId, new List<String>{paymentId});
            } else {
                subInvoiceToPaymentIdMap.get(invoiceId).add(paymentId);
            }

            paymentIdsSet.add(paymentId);
        }

        //get all processed payments related to specified subscription
        String paymentsQuery             = 'SELECT Id, Amount, RefundAmount, Status, CreatedDate, GatewayState, PaymentMethodId, Type FROM Payment';
        List<Zuora.zObject> paymentsList = ZuoraUtilities.queryMultipleZItems(zApi, paymentIdsSet, paymentsQuery, 'Id',  new List<String>{'Status = \'Processed\''});

        for(Zuora.zObject payment : paymentsList){
            String paymentId = (String)payment.getValue('Id');
            paymentsMap.put(paymentId, payment);
            paymentToPaymentMethodMap.put(paymentId, (String)payment.getValue('PaymentMethodId'));
        }

        //get payment methods for the payments
        String paymentMethodsQuery       = 'SELECT Id, Type FROM PaymentMethod';
        List<Zuora.zObject> paymentMethodsList = ZuoraUtilities.queryMultipleZItems(zApi, new Set<String>(paymentToPaymentMethodMap.values()), paymentMethodsQuery, 'Id', null);

        for(Zuora.zObject paymentMethod : paymentMethodsList){
            String paymentMethodId = (String)paymentMethod.getValue('Id');
            for(String paymentId : paymentToPaymentMethodMap.keySet()){
                if(paymentMethodId == paymentToPaymentMethodMap.get(paymentId))
                    paymentToPaymentTypeMap.put(paymentId, (String)paymentMethod.getValue('Type'));
            }
        }

        //get taxation items ids
        String taxionItemsQuery = 'SELECT Id, InvoiceItemId FROM TaxationItem'; 
        List<Zuora.zObject> taxationItemsList = ZuoraUtilities.queryMultipleZItems(zApi, subInvoiceIdsSet, taxionItemsQuery, 'InvoiceItemId', null);

        for(Zuora.zObject taxationItem : taxationItemsList){
            String invoiceItemId = (String)taxationItem.getValue('InvoiceItemId');
            String taxItemId = (String)taxationItem.getValue('Id');
            ZuoraSubscriptionCancellationWrapper wrapperItem = wrapperMap.get(invoiceItemId);
            if(wrapperItem != null){
                wrapperItem.taxationItemId = taxItemId;
                wrapperMap.put(invoiceItemId, wrapperItem);
            }
        }

        //define wrapper list
        for(String invoiceItemId : wrapperMap.keySet()){
            String paymentInvoiceId = subInvoiceItemToInvoiceMap.get(cancellationInvoiceItemToSubInvoiceItemMap.get(invoiceItemId));

            List<String> paymentIdsList = new List<String>(subInvoiceToPaymentIdMap.get(paymentInvoiceId));
            for(String paymentId : paymentIdsList){
                ZuoraSubscriptionCancellationWrapper newWrapperItem = new ZuoraSubscriptionCancellationWrapper();
                ZuoraSubscriptionCancellationWrapper wrapperItem    = wrapperMap.get(invoiceItemId);

                newWrapperItem.invoiceItemId        = invoiceItemId;
                newWrapperItem.chargeAmount         = wrapperItem.chargeAmount;
                newWrapperItem.taxAmount            = wrapperItem.taxAmount;
                newWrapperItem.taxationItemId       = wrapperItem.taxationItemId;
                newWrapperItem.totalAmount          = wrapperItem.totalAmount;

                Zuora.zObject payment               = paymentsMap.get(paymentId);
                newWrapperItem.paymentId            = paymentId;
                newWrapperItem.paymentInvoiceId     = paymentInvoiceId;
                newWrapperItem.paymentInvoiceNumber = invoiceIdToInvoiceNumberMap.get(paymentInvoiceId);
                newWrapperItem.paymentAmount        = (Decimal)payment.getValue('Amount');
                newWrapperItem.gatewayState         = (String)payment.getValue('GatewayState');
                newWrapperItem.paymentMethod        = paymentToPaymentTypeMap.get(paymentId);
                newWrapperItem.paymentType          = (String)payment.getValue('Type');
                wrapperList.add(newWrapperItem);
            }
        }

        return wrapperList;
    }
}