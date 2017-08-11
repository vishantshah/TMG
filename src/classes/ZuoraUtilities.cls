/********************************************************************
 * ZuoraUtilities
 *
 * Author: Kevin Fabregue - Zuora UK
 * ******************************************************************
 * Sally ELGhoul    19/02/2016  pass the service activation date and customer acceptance date to see the cancelation refund amount
 * #############Change Log#############
 * Modified by          Version   Change Date
 * Mantas Grigaliunas   1.1       28/06/2016    //modified createCancellationAmendment() test data creation as it was not creating valid test data 
 * Mantas Grigaliunas   1.2       29/03/2017    //added more methods to support Zuora functionality, moved test data creation code to Z_TestFactory class
 ********************************************************************/
public with sharing class ZuoraUtilities {

    /************************************************************************************
    Method Name  : zuoraApiAccess
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Zuora.zApi zuoraApiAccess() {
        Zuora.zApi zuoraApi = new Zuora.zApi();
        if (!Test.isRunningTest()) { zuoraApi.zlogin(); } //else return empty
        return zuoraApi;
    }


    /************************************************************************************
    Method Name  : queryToZuora
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    02/05/2017   Moved test data creation in Z_TestFactory class
    *************************************************************************************/
    public static List<Zuora.zObject> queryToZuora(Zuora.zApi zuoraApi, String query) {

        if (!Test.isRunningTest()) {
            return zuoraApi.zquery(query);
        } else {
            return Z_TestFactory.generateZuoraTestData(query);
        }
    }

    /************************************************************************************
    Method Name  : createZuoraObjects
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zApi.SaveResult> createZuoraObjects(Zuora.zApi zuoraApi, List<Zuora.zObject> zuoraObjectsToCreateList) {

        String log = TMGUtil.newZuoraWebServiceLog('createZuoraObjects', 'ZuoraUtilities', 
            new Map<String, Object>{'zuoraObjectsToCreateList' => String.valueOf(zuoraObjectsToCreateList)});
        List<Zuora.zApi.SaveResult> zuoraObjectsCreateResults = new List<Zuora.zApi.SaveResult>();
        try{
            if (!Test.isRunningTest()) {
                zuoraObjectsCreateResults = zuoraApi.zcreate(zuoraObjectsToCreateList);
            } else {
                Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
                res.Success = true;
                res.Id = '1234';
                zuoraObjectsCreateResults = new List<Zuora.zApi.SaveResult>{res};
            }
        }catch(Exception e){
            TMGUtil.insertZuoraWebServiceLog(log, e.getMessage(), e.getStackTraceString());
        }
        return zuoraObjectsCreateResults;
    }

    /************************************************************************************
    Method Name  : updateZuoraObjects
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zApi.SaveResult> updateZuoraObjects(Zuora.zApi zuoraApi, List<Zuora.zObject> zuoraObjectsToUpdateList) {

        String log = TMGUtil.newZuoraWebServiceLog('updateZuoraObjects', 'ZuoraUtilities',
         new Map<String, Object>{'zuoraObjectsToUpdateList' => String.valueOf(zuoraObjectsToUpdateList)});
        List<Zuora.zApi.SaveResult> zuoraObjectsUpdateResults = new List<Zuora.zApi.SaveResult>();
        try{
            if (!Test.isRunningTest()) {
                zuoraObjectsUpdateResults = zuoraApi.zupdate(zuoraObjectsToUpdateList);
            } else {
                Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
                res.Success = true;
                res.Id = '1234';
                zuoraObjectsUpdateResults = new List<Zuora.zApi.SaveResult>{res};
            }
        }catch(Exception e){
            TMGUtil.insertZuoraWebServiceLog(log, e.getMessage(), e.getStackTraceString());
        }
        return zuoraObjectsUpdateResults;
    }

    /************************************************************************************
    Method Name  : analyzeSaveResult
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : returns string list of results for a single result
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<String> analyzeSaveResult(Zuora.zApi.SaveResult saveResult) {
        return analyzeSaveResult(new List<Zuora.zApi.SaveResult>{saveResult});
    }

    /************************************************************************************
    Method Name  : analyzeSaveResult
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<String> analyzeSaveResult(List<Zuora.zApi.SaveResult> saveResults) {
        List<String> result = new List<String>();
        for(Zuora.zApi.SaveResult saveResult : saveResults){ 
            if (!(saveResult.Success)) {
                result.addAll(getErrors(saveResult.errors));
            }
        }
        return result;
    }

    /************************************************************************************
    Method Name  : getErrors
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : returns string list of errors from Zuora save results
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<String> getErrors(List<Zuora.zObject> errors){
        List<String> result = new List<String>();
        for (Zuora.zObject error : errors) {
            result.add((String)error.getValue(Constants.ZUORA_ERROR_CODE_ATTRIBUTE_NAME) + ' ' + (String)error.getValue(Constants.ZUORA_ERROR_MESSAGE_ATTRIBUTE_NAME));
        }
        return result;
    }
    /************************************************************************************
    Method Name  : createCancellationAmendment
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer           Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Sally ElGoul        19/02/2016   As part of zuora package we need to pass the service activation date and customer acceptance date
    * Mantas Grigaliunas  29/03/2017   Modified dates assignment, as it was wrong and was not correctly calculating Refund Discount amount on invoice generation
    * Mantas Grigaliunas    02/05/2017   Moved test data creation in Z_TestFactory class
    *************************************************************************************/
    public static Zuora.zApi.AmendResult createCancellationAmendment(Zuora.zApi zuoraApi, boolean preview, boolean processInvoice, 
            String zuoraSubscriptionId, String amendmentName, String amendmentDescription, String status, Date effectiveDate, 
            Date serviceActivationDate, Date invoiceDate, Date invoiceTargetDate) {

        Zuora.zObject amendment = new Zuora.zObject('Amendment');

        String today = dateZuoraFormat(Date.today());       
        
        amendment.setValue('SubscriptionId', zuoraSubscriptionId);
        amendment.setValue('Type', 'Cancellation');
        amendment.setValue('Status', status);
        
        amendment.setValue('Name', amendmentName);
        amendment.setValue('Description', amendmentDescription);
                                    
        amendment.setValue('ContractEffectiveDate', today);
        amendment.setValue('EffectiveDate', dateZuoraFormat(effectiveDate));
        
        //Sally ElGhoul pass the service activation date and customer acceptance dates
        amendment.setValue('ServiceActivationDate', dateZuoraFormat(serviceActivationDate));
        amendment.setValue('CustomerAcceptanceDate', today);

        Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
        amendRequest.amendments = new List <Zuora.zObject>{amendment};

        Zuora.zApi.InvoiceProcessingOptions invProcessOptions = new Zuora.zApi.InvoiceProcessingOptions();
        invProcessOptions.InvoiceDate = dateZuoraFormat(invoiceDate);
        invProcessOptions.InvoiceTargetDate = dateZuoraFormat(invoiceTargetDate);

        Zuora.zApi.AmendOptions amendmentOptions = new Zuora.zApi.AmendOptions();
        amendmentOptions.InvoiceProcessingOptions = invProcessOptions;
        amendmentOptions.GenerateInvoice = processInvoice;
        amendmentOptions.ProcessPayments = false;

        amendRequest.amendOptions = amendmentOptions;
        
        Zuora.zApi.PreviewOptions previewOptions = new Zuora.zApi.PreviewOptions();
        previewOptions.EnablePreviewMode = preview;
        previewOptions.NumberOfPeriods = 1;
        amendRequest.previewOptions = previewOptions;

        List<Zuora.zApi.AmendRequest> amendRequestsList = new List<Zuora.zApi.AmendRequest>{amendRequest};

        Zuora.zApi.AmendResult amendResult;

        if (!Test.isRunningTest()) {
            amendResult = zuoraApi.zamend(amendRequestsList);
            return amendResult;
        } else {
            return Z_TestFactory.createZuoraTestAmendment();
        }
    }

    /************************************************************************************
    Method Name  : dateZuoraFormat
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static String dateZuoraFormat(Date someDate) {
        return String.valueOf(someDate)+'T00:00:00';
    }


    /************************************************************************************
    Method Name  : sendNotificationEmail
    Author       : Unknown
    Created Date : Unknown
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static void sendNotificationEmail(String type, String message, Exception e) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
        //String emailAddr = 'kevin.fabregue@zuora.com';
        //String emailAddr2 = 'daniel.morton@zuora.com';          
        //String[] toAddresses = new String[] {emailAddr, emailAddr2};
        
        String[] toAddresses = Label.ZuoraErrorEmail.split(';');
        
        mail.setToAddresses(toAddresses);
        
        if (type == 'Contact') {            
            mail.setSubject('GNM | SALESFORCE - ZUORA: Contact custom synch error.');
        } else if (type == 'PM') {
            mail.setSubject('GNM | SALESFORCE - ZUORA: Payment Method change error.');
        } else {
            mail.setSubject('GNM | SALESFORCE - ZUORA: Update error.');
        }
        
        String textBody = '';
        textBody += message + '\r\n\r\n';
        if (e != null) {
            textBody += 'Exception: ' + e.getTypeName() + ' on line: ' + e.getLineNumber() + '.\r\n' + e.getMessage() + '\r\n' + e.getStackTraceString() + '\r\n\r\n';  
        }
                            
        mail.setPlainTextBody(textBody);
        try {            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
            System.Debug('###### INFO: Notification email sent to: ' + toAddresses + '\r\n The message is: ' + message);
        } catch(System.EmailException ex) {
            System.Debug('###### ERROR: ' + ex.getMessage());
        }
    }

    /************************************************************************************
    Method Name  : queryMultipleZItems
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : functionality to query Zuora objects by passing the set of values of a single field to filter by 
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zObject> queryMultipleZItems(Zuora.zApi z, Set<String> filters, String query, String conditionalFieldName, List<String> additionalConditions){

        String condition = '';
        List<Zuora.zObject> results = new List<Zuora.zObject>();

        if(filters != null && filters.size() > 0){

            condition += ' WHERE ';
            Integer counter = 0;
            for(String filter : filters){
                condition += (counter > 0 ? ' OR ' : '');
                condition += conditionalFieldName + ' = \'' + filter + '\'';
                counter ++;  
            }
            if(additionalConditions != null){
                for(String addCond : additionalConditions)
                    condition += ' AND ' + addCond;
            }
            results = queryToZuora(z, query + condition);
        }
        return results;
    }

    /************************************************************************************
    Method Name  : createCreditBalanceAdjustment
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : defines zuora record of CreditBalanceAdjustment
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Zuora.zObject createCreditBalanceAdjustment(Decimal amount, String sourceTransactionId, String cbaType){
        Zuora.zObject cba = new Zuora.zObject('CreditBalanceAdjustment');
        cba.setValue('AccountingCode', '');
        cba.setValue('Amount', amount);
        cba.setValue('ReasonCode', '');
        cba.setValue('ReferenceId', '');
        cba.setValue('SourceTransactionId', sourceTransactionId);
        cba.setValue('Type', cbaType);
        return cba;
    }

    /************************************************************************************
    Method Name  : createRefund
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : defines zuora record of Refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Zuora.zObject createRefund(String zAccountId, Decimal amount, String paymentId, String sourceType, String refundType){
        Zuora.zObject refund = new Zuora.zObject('Refund');
        refund.setValue('AccountId', zAccountId);
        refund.setValue('Amount', amount);
        refund.setValue('PaymentId', paymentId);
        refund.setValue('SourceType', sourceType);
        refund.setValue('Type', refundType);
        return refund;
    }

    /************************************************************************************
    Method Name  : createInvoiceItemAdjustment
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : defines zuora record of InvoiceItemAdjustment 
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Zuora.zObject createInvoiceItemAdjustment(Date adjustDate, Decimal amount, String invoiceId, String invoiceNumber, 
        String sourceId, String sourceType, String adjustType){
        Zuora.zObject itemAdjustment = new Zuora.zObject('InvoiceItemAdjustment');
        itemAdjustment.setValue('AdjustmentDate', String.valueOf(adjustDate).substring(0, 10));
        itemAdjustment.setValue('Amount', amount);
        itemAdjustment.setValue('InvoiceId', invoiceId);
        itemAdjustment.setValue('InvoiceNumber', invoiceNumber);
        itemAdjustment.setValue('SourceId', sourceId);
        itemAdjustment.setValue('SourceType', sourceType);
        itemAdjustment.setValue('Type', adjustType);
        return itemAdjustment;
    }

    /************************************************************************************
    Method Name  : calculateAdjustmentValue
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : calculates adjustment charge and tax values from total amount 
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Map<Decimal, Decimal> calculateAdjustmentValue(Decimal chargeAmount, Decimal taxAmount, Decimal adjustmentAmount){

        Map<Decimal, Decimal> adjustmentAmountMap = new Map<Decimal, Decimal>();
        //calculate percentage
        Decimal percentageValue = (taxAmount * 100)/chargeAmount;
        Decimal adjustedTaxAmount = (percentageValue * adjustmentAmount)/100;
        Decimal adjustedChargeAmount = adjustmentAmount - adjustedTaxAmount;
        adjustmentAmountMap.put(adjustedChargeAmount.setScale(2), adjustedTaxAmount.setScale(2));
        return adjustmentAmountMap;
    }

    /************************************************************************************
    Method Name  : getPaymentMethodType
    Author       : Mantas Grigaliunas
    Created Date : 29/03/2017
    Function     : gets payment method type from zuora account
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static String getPaymentMethodType(Zuora.zApi z, String accountId){
        String paymentType = '';
        String zoql = 'SELECT Id, Type FROM PaymentMethod WHERE AccountId  = \'' + accountId + '\'';
        List<Zuora.zObject> paymentMethod = new List<Zuora.zObject>();
        if(!Test.isRunningTest()){
            paymentMethod = z.zquery(zoql);
        } else {
            paymentMethod = Z_TestFactory.createZuoraPaymentMethods();
        }
        return (String)paymentMethod.get(0).getValue('Type');
    }

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        10/8/2015
    Function    convert zuora Date fields
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Date getDateValue(String strZuoraDateValue){
        
        //this means the return value from Zuora contains time so it is an old record before the wsdl changes
        if(strZuoraDateValue.contains('T')){
            return date.valueOf(strZuoraDateValue.substringBefore('T'));
        }
        //if the value is 2015-08-10 00:00:00 not 2015-08-10T00:00:00
        if(strZuoraDateValue.contains(' ')){
            return date.valueOf(strZuoraDateValue.substringBefore(' '));
        }
        //no time in the value
        return date.valueOf(strZuoraDateValue);
    }

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        4/8/2015
    Function    return the end of term value
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Date getEndOfTermValue(Boolean isSubscriptionMonthly, Date subscriptionNextChargeDate, Date subscriptionEndDate){
        //if the subscription is monthly return the next charge date
        if (isSubscriptionMonthly && subscriptionNextChargeDate != null) return subscriptionNextChargeDate; 
        else return subscriptionEndDate;
    }
}