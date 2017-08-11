/* ------------------------------------------------------------------------------
   Name:        CreditCardExpiryDateUpdateBatch.cls
   Description: Batch class to update CreditCardExpiryDate on Account

   Date         Version Author              Summary of Changes 
   -----------  ------- -----------------   -------------------------------------
   22/10/2015   1.1     Cristina Anghenie   mpp call to get the latest CreditCardExpiryDate     
   31/05/2016   1.2     Pawel Chrzanowski   modified logic
   27/07/2016   1.3     Pawel Chrzanowski   failed DML record ID fix
--------------------------------------------------------------------------------- */
global class CreditCardExpiryDateUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public Map<Id, String> mapFailedRecords = new Map<Id, String>();
    public static final Integer ERROR_LIMIT = 800;
    public Integer successCount = 0;
    public Integer failCount = 0;
    public Integer noChangeCount = 0;
    public Integer totalToUpdate = 0;
    public Boolean registrantsOnly = false;

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 31/05/2016
    Version - 1.0
    Function - batch constructors
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    global CreditCardExpiryDateUpdateBatch(String optionParam){
        if(optionParam.toLowerCase() == Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME.toLowerCase()){
            registrantsOnly = true;
        }
    }

    global CreditCardExpiryDateUpdateBatch(){}
   
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 22/10/2015
    Version - 1.0
    Function - method that queries the record that have cc expiry data due to expire
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         16/11/2015  //filter query using date interval for cc expiry date
    Cristina Anghenie   1.2         25/11/2015  //check Credit_Card_Expiry_Date__c for all records from the past to until 30 days from today
    Pawel Chrzanowski   1.3         31/05/2016  //added fields
    *************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC){
        General__c noOfDaysCCExpiryDate = General__c.getInstance(Constants.GENERAL_DAYS_CC_EXPIRY_DATE);
        
        if(noOfDaysCCExpiryDate == null || String.isBlank(noOfDaysCCExpiryDate.Value__c) || !noOfDaysCCExpiryDate.Value__c.isNumeric()) throw new TelegraphApplicationException(Label.NoOfDay_CC_Expiry_Date);
        Integer i = Integer.valueOf(noOfDaysCCExpiryDate.Value__c);
        
        Date dt = System.today().addDays(i);

        String registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());

        String query = 'SELECT Id, Subscriber_Number_Static__c, Credit_Card_Expiry_Date__c, RecordTypeId, '+
                       '(SELECT Zuora__Default_Payment_Method__c, Zuora__Default_Payment_Method__r.Zuora__CreditCardExpirationMonth__c, Zuora__Default_Payment_Method__r.Zuora__CreditCardExpirationYear__c FROM Zuora__R00N40000001kyLcEAI__r WHERE Zuora__Default_Payment_Method__r.Zuora__DefaultPaymentMethod__c = true AND Zuora__Default_Payment_Method__r.Zuora__Type__c = \'' + Constants.MPP_PAYMENTMETHOD_CC + '\') '+
                       'FROM Account '+
                       'WHERE (Digital_Status__c = \'' + Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE + '\' ' +
                              'OR Subscriber_Digital_Status__c = \'' + Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE + '\' ' +
                              'OR Subscription_Status__c = \'' + Constants.SSTATUS_ACTIVE + '\' OR Subscription_Status__c = \'' + Constants.SSTATUS_PENDING + '\') ' +
                       'AND (Credit_Card_Expiry_Date__c <= :dt OR Credit_Card_Expiry_Date__c = null)' +
                       (registrantsOnly ? ' AND RecordTypeId = :registrantRecordTypeId' : '');

        return Database.getQueryLocator(query);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 22/10/2015
    Version - 1.0
    Function - method that updates ccExpiryDate field from MPP 
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         31/05/2016  //modified logic
    *************************************************************************************/
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Account> lstAccounts = (List<Account>)scope;
        List<Account> lstRegistrants = new List<Account>();
        List<Account> lstNonRegistrants = new List<Account>();
        List<Account> accsToUpdate = new List<Account>();
        String debugLog = '### CreditCardExpiryDateUpdateBatch.execute -> batch size: ' + lstAccounts.size() + '\r\n';

        Id registrantId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
        if(registrantId == null) throw new TelegraphApplicationException(Label.Registrant_Id_not_Found);

        for(Account acc : lstAccounts){
            if(acc.RecordTypeId == registrantId){
                lstRegistrants.add(acc);
            }else{
                lstNonRegistrants.add(acc);
            }
        }

        //Registrants
        debugLog += '\r\nRegistrants size: ' + lstRegistrants.size() + '\r\n';
        if(!lstRegistrants.isEmpty()){
            for(Account acc : lstRegistrants){
                if(acc.Zuora__R00N40000001kyLcEAI__r.size() == 1){
                    Zuora__CustomerAccount__c billingAccount = acc.Zuora__R00N40000001kyLcEAI__r[0];
                    if(TMGUtil.isDataValid(billingAccount.Zuora__Default_Payment_Method__c) && TMGUtil.isDataValid(billingAccount.Zuora__Default_Payment_Method__r.Zuora__CreditCardExpirationMonth__c) && TMGUtil.isDataValid(billingAccount.Zuora__Default_Payment_Method__r.Zuora__CreditCardExpirationYear__c)){
                        Integer year = Integer.valueOf(billingAccount.Zuora__Default_Payment_Method__r.Zuora__CreditCardExpirationYear__c);
                        Integer month = Integer.valueOf(billingAccount.Zuora__Default_Payment_Method__r.Zuora__CreditCardExpirationMonth__c);
                        Integer noOfDays = date.daysInMonth(year,month);
                        Date ccExpiryDate = Date.newInstance(year,month,noOfDays);
                        debugLog += '  found ccExpiryDate for Registrant: ' + ccExpiryDate + '\r\n';
                        if(acc.Credit_Card_Expiry_Date__c != ccExpiryDate){
                            acc.Credit_Card_Expiry_Date__c = ccExpiryDate;
                            accsToUpdate.add(acc);
                            totalToUpdate++;
                        }else{
                            noChangeCount++;
                            debugLog += 'Account Id: ' + acc.Id + ', no change.' + '\r\n';
                        }
                    }else debugLog += 'Account Id: ' + acc.Id + ', invalid Payment Method data.' + '\r\n';
                }else debugLog += 'Account Id: ' + acc.Id + ', incorrect number of related Billing Accounts: ' + acc.Zuora__R00N40000001kyLcEAI__r.size() + '\r\n';
            }
        }

        //Non Registrants
        debugLog += '\r\nNon Registrants size: ' + lstNonRegistrants.size() + '\r\n';
        if(!lstNonRegistrants.isEmpty()){
            MPPInterfaceHTTP mppHTTP = new MPPInterfaceHTTP();
            Map<String, Account> accsToProcess = new Map<String,Account>();
            Map<Id, Id> mapAccountIdToLatestSubscription = new Map<Id, Id>();
            Map<Id, Id> mapAccountIdToLatestTransaction = new Map<Id, Id>();
            
            Date dtFrom = Date.today().addYears(-2);
            for(Subscription__c sub : [SELECT   Id,
                                                Subscriber__c 
                                            FROM Subscription__c 
                                            WHERE Subscriber__c in :lstNonRegistrants 
                                            AND Payment_Type__c = :Constants.SUB_PMETHOD_CC 
                                            AND isContinuous__c = true
                                            AND CreatedDate > : dtFrom 
                                            ORDER BY CreatedDate DESC]){
                if(!mapAccountIdToLatestSubscription.containsKey(sub.Subscriber__c)){
                    mapAccountIdToLatestSubscription.put(sub.Subscriber__c, sub.Id);
                }                       
            }

            for(MPP_Transaction_History__c mpp : [SELECT    Id,
                                                            Subscriber__c
                                                        FROM MPP_Transaction_History__c
                                                        WHERE Subscriber__c in :lstNonRegistrants
                                                        AND DD_Account_Name__c = null 
                                                        AND DD_Account_Number__c = null 
                                                        AND DD_Sort_Code__c = null
                                                        AND CreatedDate > : dtFrom  
                                                        ORDER BY CreatedDate DESC]){
                if(!mapAccountIdToLatestTransaction.containsKey(mpp.Subscriber__c)){
                    mapAccountIdToLatestTransaction.put(mpp.Subscriber__c, mpp.Id);
                }
            }
   
            for(Account acc : lstNonRegistrants){
                if(mapAccountIdToLatestSubscription.containsKey(acc.Id) || mapAccountIdToLatestTransaction.containsKey(acc.Id)){
                    accsToProcess.put(acc.Subscriber_Number_Static__c, acc);
                }
            }
        
            if(!accsToProcess.keySet().isEmpty()){
                MPPInterfaceHTTP.PaymentDetailResult[] ccDetails = mppHTTP.getBulkPaymentDetailResultBasedOnTSNumbers(accsToProcess.keySet());
                for(MPPInterfaceHTTP.PaymentDetailResult ccDetail : ccDetails){
                    if(String.isNotBlank(ccDetail.creditCardExpiryDate)){
                        Integer year = Integer.valueOf('20'+ ccDetail.creditCardExpiryDate.substringAfter('/'));
                        Integer month = Integer.valueOf(ccDetail.creditCardExpiryDate.substringBefore('/'));
                        Integer noOfDays = date.daysInMonth(year,month);
                        Date ccExpiryDate = Date.newInstance(year,month,noOfDays);
                        if(accsToProcess.get(ccDetail.tsNumber).Credit_Card_Expiry_Date__c != ccExpiryDate){
                            accsToProcess.get(ccDetail.tsNumber).Credit_Card_Expiry_Date__c = ccExpiryDate;
                            accsToUpdate.add(accsToProcess.get(ccDetail.tsNumber));
                            totalToUpdate++;
                        }else{
                            noChangeCount++;
                        }
                    }
                }
            }
        }

        debugLog += '\r\nAccounts to update size: ' + accsToUpdate.size() + '\r\n';
        if(!accsToUpdate.isEmpty()){
            AccountTriggerHandler.getInstance().isExecuting = true;
            AccountTriggerHandler.getInstance().bRunAPI = false;
            Database.SaveResult[] lstResults = Database.update(accsToUpdate, false);
            AccountTriggerHandler.getInstance().isExecuting = false;
            AccountTriggerHandler.getInstance().bRunAPI = true;

            for(Integer i=0; i<lstResults.size(); i++){
                if(lstResults[i].isSuccess()){
                    successCount++;
                }else{
                    failCount++;
                    for(Database.Error err : lstResults[i].getErrors()){
                        debugLog += '  DML update error: ' + err.getStatusCode() + ', ' + err.getFields() + ', ' + err.getMessage() + '\r\n';
                        if(mapFailedRecords.size() <= ERROR_LIMIT){
                            mapFailedRecords.put(accsToUpdate[i].Id, err.getStatusCode() + ', ' + err.getFields() + ', ' + err.getMessage());
                        }
                    }
                }
            }
        }
        debugLog += 'noChangeCount: ' + noChangeCount + ', totalToUpdate: ' + totalToUpdate + '\r\n';
        System.debug(debugLog);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 22/10/2015
    Version - 1.0
    Function - method that sends an email with all records there were failing up update ccExpiryDate field
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         31/05/2016  modified sHtml and email condition
    *************************************************************************************/
    global void finish(Database.BatchableContext BC){
        Integer totalCount = noChangeCount + totalToUpdate;
        System.debug('### CreditCardExpiryDateUpdateBatch.finish -> success: ' + successCount + ', fail: ' + failCount + ', no change: ' + noChangeCount + ', total: ' + totalCount);
        if(failCount == 0) return;

        List<String> lstExtraTo = new List<String>();
        String errorRows = '';

        General__c recipient = General__c.getInstance(Constants.SUBSCRIPTION_STATUS_BATCH_ERROR_USERID);
        if(recipient != null && String.isNotBlank(recipient.Value__c)){
            lstExtraTo.add(recipient.Value__c);
        }

        for(Id res : mapFailedRecords.keySet()){
            errorRows += '<tr><td>' + res + '</td><td>' + mapFailedRecords.get(res) + '</td></tr>';
        }
        if(String.isNotBlank(errorRows)){
            errorRows = '<table><tr><td>Account ID</td><td>Errors</td></tr>' + errorRows + '</table>';
        }

        String sHtml = String.format(Label.Account_CC_Expiry_Batch_Finish_email_content, new List<String>{String.valueOf(successCount) + '/' + String.valueOf(totalCount), String.valueOf(failCount) + '/' + String.valueOf(totalCount), String.valueOf(noChangeCount) + '/' + String.valueOf(totalCount), errorRows});

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(Label.Subscription_Status_Batch_Finish_Email_Subject);
        email.setTargetObjectId(System.UserInfo.getUserId());
        if(!lstExtraTo.isEmpty()){
            email.setToAddresses(lstExtraTo);
        }
        email.setHTMLBody(sHtml);
        email.setSaveAsActivity(false);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}