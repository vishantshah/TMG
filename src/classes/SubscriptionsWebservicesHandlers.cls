/**
* @author Unknown
* @date Unknown
* @description PP-2: Business logic for the Supscription Web Services
Dependencies: WebserviceUtil
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   	1.1		02/03/2015  //modified createSubscription()
Wiktor Czykin   	1.2     02/06/2015  //modified updateSuccessPaymentScheduleSetup(), updateFailedPaymentScheduleRequests(), updateFailedUserManageRequests()
Wiktor Czykin   	1.3    	24/06/2015  //modified updateFailedPaymentScheduleRequests(), updateSuccessPaymentScheduleSetup(), removed overloaded updateSuccessPaymentScheduleSetup() as never used
Wiktor Czykin   	1.4     14/07/2015  //modified
Wiktor Czykin   	1.5     06/08/2015  //modified setAccountFields()
Cristina Anghenie	1.6     11/08/2015  //remove unneccesary debugs and commented out code and populate MPP_Pay_Schedule_Start_Date__c and MPP_Pay_Schedule_End_Date__c
Cristina Anghenie	1.7     14/09/2015  //update updateFailedPaymentScheduleRequests()
Cristina Ang    	1.8     21/09/2015  //temporary add subscriptionType=13weeks to ValidatePOC even though the allow13weeks is unticked
Wiktor Czykin   	1.9     22/09/2015  //change to setAccountFields();
Wiktor Czykin   	2.0     05/10/2015  //change to setMPPSubscriptionFields()
Wiktor Czykin   	2.1     21/10/2015  //change to setMPPSubscriptionFields();
Wiktor Czykin   	2.2     30/11/2015  //modified createSubscription(), added createSubscription() overload,  modified updateSubscription(), added updateSubscription() overload
Michal Szewczyk 	2.3     13/01/2016  //changed createsubscription()
Wiktor Czykin   	2.4     15/01/2016  //mnodified setSubscriptionLowStartDetails();
Wiktor Czykin   	2.5     02/02/2016  //modified getIncentives()
Wiktor Czykin   	2.6     26/02/2016  //modified setAccountFields();
Pawel Chrzanowski 	2.7     02/03/2016  //modified DDSetupFailure() and digitalSubscriptionEnded()
Michal Szewczyk 	2.7     14/03/2016  //replaced payment checkboxes with multipick list
Pawel Chrzanowski  	2.8     29/03/2016  //modified getAccountByTSNumber() query string
Michal Szewczyk 	2.9     01/04/2016  //changes around new data model
Michal Szewczyk 	3.0     24/05/2016  //added setEntitlements() and extractValue()
Wiktor Czykin   	3.1     25/05/2016  //added setEntitlements()
Wiktor Czykin   	3.2     27/05/2016  //modified getPOCStatus() - prod hotfix
Mantas Grigaliunas 	3.3	09/06/2016  //removed ipad related method getTCodeFromSubscriberDetails and some code that is not required anymore after android and ipad types are depricated on the system
Michal Szewczyk 	3.4     17/06/2016  //modified getPOCStatus() - production hotfix
Wiktor Czykin       3.5     20/06/2016  //modified getPOCStatus() - fix to the fix above
Michal Szewczyk     3.6     18/10/2016  //modified setTransactionFields() - added oneOffPayment reason param
Wiktor Czykin       3.7     03/02/2017  //modified validateSubscriber() and setAccountFields() methods
**/
public class SubscriptionsWebservicesHandlers {

    private static final Set<String> paymentStatuses = new Set<String>{'success', 'successwithoutpayment', 'failed', 'cancelled', 'refund'};
    private static final Set<String> paymentTypes = new Set<String>{'directdebit', 'creditdebitcard'};
    private static final Set<String> VATtypes = new Set<String>{'vat_0', 'vat_20'};
    private static final Set<String> digitalSubscriberStatuses = new Set<String>{'active', 'inactive'};
    private static final Set<String> flowTypes = new Set<String>{'openofferflow', 'pocflow', 'promotionflow','bulkflow','bulkfixed'};
    private static final Set<String> productTypes = new Set<String>{'premium', 'digital', 'webpack'};
    private static final Set<String> origins = new Set<String>{'online', 'offline', 'mobile'};
    private static final Set<String> subscriptionTypes = new Set<String>{   Constants.SUBSCRIPTIONTYPE_MONTHLY,
                                                                            Constants.SUBSCRIPTIONTYPE_YEARLY,
                                                                            Constants.SUBSCRIPTIONTYPE_26WEEKS,
                                                                            Constants.SUBSCRIPTIONTYPE_52WEEKS,
                                                                            Constants.SUBSCRIPTIONTYPE_CONTINUOUS};
    private static final Map<String,String> subscriberTypes = new Map<String,String>{'digital' => Constants.RECTYPE_DIGISUB, 'premium' => Constants.RECTYPE_INDIVSUB, 'webpack' => Constants.RECTYPE_DIGISUB};
    private static final Set<String> devices = new Set<String>{'website', 'mobile', 'tablet'};

    @TestVisible private static Boolean TESTFAILACCOUNT_LAST = false;
    @TestVisible private static Boolean TESTFAILSUBSCRIPTION_ALL = false;

    // Create a subscriber and return the TSNumber for it
    public static String createSubscriber(SubscriptionsWebservices.Subscriber subscriberDetails){
        return createSubscriber(subscriberDetails, null, null,null);
    }

    /**
     * Creates a subscriber and return the TSNumber for it.
     *
     * @param subscriberDetails     the subscriber details
     * @param paymentDetails        the payment details associated with the subscriber
     * @param subscriptionDetails   the subscription details
     * @param recurringDetails      the recurring info associated with the subscriber
     * @return the TSNumber generated for the subscriber
     */
    public static String createSubscriber(  SubscriptionsWebservices.Subscriber subscriberDetails,
                                            SubscriptionsWebservices.Payment paymentDetails,
                                            SubscriptionsWebservices.Subscription subscriptionDetails,
                                            SubscriptionsWebservices.MPPRecurringInfo recurringDetails){
        System.debug('recurringDetails='+recurringDetails);
        if(subscriberDetails == null){
            throw new WebserviceUtil.NullParameterException('subscriberDetails', '');
        }
        validateSubscriber(subscriberDetails, true);
        if (String.IsBlank(subscriberDetails.GUID)){
            throw new WebserviceUtil.NullGuidException();
        }
        if( !isGUIDAvailable(subscriberDetails.GUID) ){
            throw new WebserviceUtil.GuidInUseException();
        }
        Account a = setAccountFields(new Account(), subscriberDetails, paymentDetails, subscriptionDetails,recurringDetails);
        try{
            insert a;
        } catch (DmlException e) {
            handleSingleDMLException(e, a);
        }

        // The TSNumber was not in the original Account object so select it now
        a = [Select Subscriber_Number_static__c From Account Where id = : a.id limit 1];
        return a.Subscriber_Number_static__c;
    }


    //Update a Subscriber Status
    public static void updateSubscriber_EmailSent_MPPServiceID(String TsNumber, String MppServiceId){
        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        Account a = getAccountByTSNumber(TSNumber);
        if(a == null)
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);

        // Update the field that tells if we are using MPP (and not payonomy)
        a.isUsingMPP__c = true;
        // Update MPP Service ID: usefulll for Cancel
        a.MPP_Service_Id__c = (String.isBlank(MppServiceId)) ? PlaneURL__c.getInstance('MPP').Premium_Continuous_ID__c : MppServiceId;
        System.debug('### Account MPP UPDATE: ' + a.isUsingMPP__c + ' ------ ' + a.MPP_Service_Id__c);
        update a;
    }

    //Update a Subscriber
    public static void updateSubscriber(SubscriptionsWebservices.Subscriber subscriberDetails){
        updateSubscriber(subscriberDetails, null, null);
    }


    //Update Previous Promocode,Previous Promoname,Previous PromoExpiaryDate
    public static void updateSubscriber(SubscriptionsWebservices.Subscriber subscriberDetails, SubscriptionsWebservices.Payment paymentDetails, SubscriptionsWebservices.Subscription subscriptionDetails){

        if(subscriberDetails == null){
            throw new WebserviceUtil.NullParameterException('subscriberDetails', '');
        }
        validateSubscriber(subscriberDetails, false);

        Account a = getAccountByTSNumber(subscriberDetails.TSNumber);
        if(a == null)
            throw new WebserviceUtil.UnknownTSNumberException('3',subscriberDetails.TSNumber);

        if(subscriberDetails.GUID == null)
            subscriberDetails.GUID = a.Guid__c;

        a = setAccountFields(a, subscriberDetails, paymentDetails, subscriptionDetails,null);
        try{
            upsert a;
        } catch (DmlException e) {
            handleSingleDMLException(e, a);
        }
    }

    /** Create a MPP transaction history record  */
    public static void createTransaction(String TSNumber, SubscriptionsWebservices.Payment paymentDetails, SubscriptionsWebservices.DirectDebitInfo directDebitDetails, Boolean updateSubOnMapping){
        createTransaction(TSNumber,paymentDetails,directDebitDetails,updateSubOnMapping,null);
    }

    /** Create a MPP transaction history record */
    public static void createTransaction(String TSNumber, SubscriptionsWebservices.Payment paymentDetails, SubscriptionsWebservices.DirectDebitInfo directDebitDetails, Boolean updateSubOnMapping,SubscriptionsWebservices.CustomParameter[] clientCustomParam){

        System.debug('### TSNumber: ' + TSNumber);
        System.debug('### directDebitDetails: ' + directDebitDetails);

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }
        if(paymentDetails == null){
            throw new WebserviceUtil.NullParameterException('paymentDetails', '');
        }

        // Only validate the payment details if they exist
        if(paymentDetails.paymentStatus != 'successwithoutpayment'){
            validatePayment(paymentDetails);
        }

        Account a = getAccountByTSNumber(TSNumber);
        if(a == null){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        Boolean updateAccount = false;
        Boolean updateAcctCurrPaySchdlEndDate = false;

        if(paymentDetails.serviceId!=null && a.MPP_Service_Id__c != paymentDetails.serviceId){
            a.MPP_Service_Id__c = paymentDetails.serviceId;
            updateAccount = true;
        }else if(paymentDetails.serviceId == null){
            a.MPP_Service_Id__c = PlaneURL__c.getInstance('MPP').Premium_Continuous_ID__c;
            updateAccount = true;
        }

        //PP-1701 - Do not update IsUsingMPP flag if it is One-Off Payment
        Boolean isOneOffPayment = (TMGUTil.isDataValid(paymentDetails.productName) && paymentDetails.productName.toLowerCase().equals('oneoffpayment'));
        if(!a.IsUsingMPP__c && !isOneOffPayment){
            a.IsUsingMPP__c = true;
            updateAccount = true;
        }


        // No transaction history as no payment has taken
        MPP_Transaction_History__c t = null;
        Boolean txnHistInsertError = false;
        DmlException dmlEx;
        if(paymentDetails.paymentStatus != 'successwithoutpayment'){
            Id individualSubscriberRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());
            if (clientCustomParam == null){
                t = setTransactionFields(new MPP_Transaction_History__c(), a.id, (a.RecordTypeId == individualSubscriberRecordTypeId), paymentDetails, directDebitDetails, updateSubOnMapping);
            }else{
                t = setTransactionFields(new MPP_Transaction_History__c(), a.id, (a.RecordTypeId == individualSubscriberRecordTypeId), paymentDetails, directDebitDetails, updateSubOnMapping,clientCustomParam);
            }

            /* This should not be udpated in case of One Off Payment.
             * To ensure that a renewal on a MPP to MPP renewed sub,
             * the Account.currentPayscheduleEndDate should always reflect the subscription's current schedule end date
             */
            if(!isOneOffPayment) {
                if(t.Subscription__c != null) { // this signifies that the txn hist was associated with sub's premium sub id (mpp payment schedule id)
                    // get the associated subscription's MPP Pay Schedule End Date
                    Subscription__c tempSub = [select Id, MPP_Pay_Schedule_End_Date__c from Subscription__c where Id = :t.Subscription__c limit 1];

                    //Convert datetime MPP_Pay_Schedule_End_Date__c to date so that we can compare the value with that of the Account
                    Date mppPayScheduleEndDate;
                    if(tempSub.MPP_Pay_Schedule_End_Date__c != null){
                        mppPayScheduleEndDate = Date.newInstance(tempSub.MPP_Pay_Schedule_End_Date__c.year(), tempSub.MPP_Pay_Schedule_End_Date__c.month(), tempSub.MPP_Pay_Schedule_End_Date__c.day());
                    }

                    //Don't do anything if there's no date!
                    if(mppPayScheduleEndDate != null && a.MPP_CurrentPayScheduleEndDate__c != mppPayScheduleEndDate) {
                        System.debug('PP-1615 :  Current Pay Schedule End Date on Account [' + a.MPP_CurrentPayScheduleEndDate__c + '] not same as MPP Pay Schedule End Date on Subscription [' + tempSub.MPP_Pay_Schedule_End_Date__c + ']');
                        a.MPP_CurrentPayScheduleEndDate__c = mppPayScheduleEndDate;
                    }
                }
            }

            //This is make sure, we always have default Auddis record exist before payment record is created.
            if(t.Subscription__c!=null){
                createAUDDISTransactionHistoryRecord(TSNumber, t.Subscription__c,directDebitDetails);
            }
            try{
                insert t;
            }catch(DmlException e) {
                txnHistInsertError = true;
                dmlEx = e;
            }
        }

        /* Changed location of update call on Account and handling DmlException on txnHist during insert for PP-1615 */
        // this need to be updated once subscription on the txn hist has been found to populate the current pay schedule end date
        // on the Aaccount from the Subscription found for the payment schedule id
        if(updateAccount){
            update a;
        }

        // handle the txn history insert error if any after account has been udpated
        if(txnHistInsertError) {
            handleSingleDMLException(dmlEx, t);
        }
    }


    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  Create the junction object between subscriber and incentive - this shows the incentive that was selected
                by the user during acquisition
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void createSubscriberIncentive(String sTSNumber, String sSubscriptionId, String sIncentiveId){
        if(String.isBlank(sIncentiveId) ||String.isBlank(sTSNumber))
            return;

        List<Account> accs = [SELECT Id FROM Account WHERE Subscriber_Number_Static__c = :sTSNumber];
        if(accs.isEmpty()) return;

        SubscriptionIncentiveAssociation__c rel = new SubscriptionIncentiveAssociation__c(Subscriber__c = accs[0].Id,
                                                                                          Subscription__c = sSubscriptionId,
                                                                                          Incentive__c = sIncentiveId,
                                                                                          Reason__c = 'Acquisition Incentive',
                                                                                          Date_Requested__c = System.today());
        try{
            insert rel;
        } catch (DmlException e) {
            handleSingleDMLException(e, rel);
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  createAUDDISTransactionHistory records
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         26/10/2015  //set DD account name to 255chars in case is longer than that
    ****************************************************************************************/
    public static void createAUDDISTransactionHistoryRecord(Boolean isMovedFromFixedToCont, String TSNumber,  Id subscriptionId, SubscriptionsWebservices.DirectDebitInfo directDebitDetails){
        System.debug('Inside new createAUDDISTransactionHistoryRecord');
        Account a = getAccountByTSNumber(TSNumber);

        String logmessage = 'Into the method createAUDDISTransactionHistoryRecord';

        if(a == null){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
            logmessage += ', Account is empty';
            TMGUtil.logWebServiceRequest('Inbound', 'AUDDIS, TS Number '+TSNumber, 'createAUDDISTransactionHistoryRecord',null,'Account is null '+logMessage);
            system.debug('#### Account is null in createAUDDISTransactionHistoryRecord ####');
            return;
        }

        //Check for any existing Auddis record, create if not found or if Ref no. is different.
        boolean foundAuddisRef = false;
        system.debug('#### Account is null in createAUDDISTransactionHistoryRecord ####');
        try{
            List<MPP_Transaction_History__c> mppTransactions = [Select AUDDIS_Ref__c from MPP_Transaction_History__c where Payment_status__c = 'Success' and Subscriber__c=:a.Id and DD_Transaction_Type__c = 'AUDDIS'];
            system.debug('#### Found AUDDIS  mppTransaction: #### '+mppTransactions);
            if (directDebitDetails == null){
                if (mppTransactions != null && mppTransactions.size() >= 1) {
                    foundAuddisRef = true;
                }
            }else{
                for(MPP_Transaction_History__c rec: mppTransactions){
                    if(rec.AUDDIS_Ref__c == directDebitDetails.auddisRef)
                        {
                        foundAuddisRef = true;
                        break;
                    }
                }
            }
        }catch(Exception ex){
             system.debug('#### mppTransactions is null in createAUDDISTransactionHistoryRecord ####');
        }
        //If Auddis Ref no is already exist for Account then dont create new record.
        if(!foundAuddisRef && directDebitDetails !=null){
            MPP_Transaction_History__c txn = new MPP_Transaction_History__c(DD_Transaction_Type__c = 'AUDDIS',
            DD_Account_Name__c = (directDebitDetails.accountName !=null ? directDebitDetails.accountName.LEFT(100) : directDebitDetails.accountName),
            DD_Account_Number__c = directDebitDetails.accountNumber,
            DD_Sort_Code__c = directDebitDetails.sortCode,
            Payment_status__c ='Success',
            Subscriber__c = a.Id,
            Subscription__c = subscriptionId,
            AUDDIS_Ref__c=directDebitDetails.auddisRef,
            Payment_Submission_Date__c=directDebitDetails.submittedPaymentDate);

            try{
                insert txn;
                system.debug('#### AUDDIS row created createAUDDISTransactionHistoryRecord ####');
            } catch (DmlException e) {
                handleSingleDMLException(e, txn);
                system.debug('#### AUDDIS row creation failed createAUDDISTransactionHistoryRecord ####, message: '+e.getMessage());
                logmessage+=e.getMessage();
                TMGUtil.logWebServiceRequest('createAUDDISTransactionHistoryRecord', TSNumber, 'createAUDDISTransactionHistoryRecord',null,'logmessage: '+logmessage);
            }
        }

        if(!foundAuddisRef && directDebitDetails ==null && isMovedFromFixedToCont==true){
            System.debug('Inside Direct debit null'+subscriptionId);
            MPP_Transaction_History__c txn = new MPP_Transaction_History__c(DD_Transaction_Type__c = 'AUDDIS',
                Payment_status__c ='Success',
                Subscriber__c = a.Id,
                Subscription__c = subscriptionId);

            try{
                insert txn;
            } catch (DmlException e) {
                handleSingleDMLException(e, txn);
                system.debug('#### AUDDIS row creation failed createAUDDISTransactionHistoryRecord ####, for fixed to continuous message: '+e.getMessage());
                TMGUtil.logWebServiceRequest('createAUDDISTransactionHistoryRecord', TSNumber, 'createAUDDISTransactionHistoryRecord',null,'for fixed to continuous logmessage: '+logmessage);
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  createAUDDISTransactionHistory records
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         26/10/2015  //set DD account name to 255chars in case is longer than that
    ****************************************************************************************/
    public static void createAUDDISTransactionHistoryRecord(String TSNumber, Id subscriptionId, SubscriptionsWebservices.DirectDebitInfo directDebitDetails){

        if(directDebitDetails == null){
            return;
        }

        Account a = getAccountByTSNumber(TSNumber);
        if(a == null){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
            return;
        }

        //MIrfan@Appirio, 260412. Plane 1.2, Check for any existing Auddis record, create if not found or if Ref no. is different.
        boolean foundAuddisRef = false;

        for(MPP_Transaction_History__c rec: [Select AUDDIS_Ref__c from MPP_Transaction_History__c where Payment_status__c = 'Success' and Subscriber__c=:a.Id and DD_Transaction_Type__c = 'AUDDIS'])
        {

            if(rec.AUDDIS_Ref__c == directDebitDetails.auddisRef)
                {
                foundAuddisRef = true;
                break;
            }

        }

        //If Auddis Ref no is already exist for Account then dont create new record.
        if(!foundAuddisRef){

            MPP_Transaction_History__c txn = new MPP_Transaction_History__c(DD_Transaction_Type__c = 'AUDDIS',
                DD_Account_Name__c = (directDebitDetails.accountName !=null ? directDebitDetails.accountName.LEFT(100) : directDebitDetails.accountName),
                DD_Account_Number__c = directDebitDetails.accountNumber,
                DD_Sort_Code__c = directDebitDetails.sortCode,
                Payment_status__c ='Success',
                Subscriber__c = a.Id,
                Subscription__c = subscriptionId,
                AUDDIS_Ref__c=directDebitDetails.auddisRef,
                Payment_Submission_Date__c=directDebitDetails.submittedPaymentDate);


                try{
                    insert txn;
                } catch (DmlException e) {
                    handleSingleDMLException(e, txn);
                }

        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  createAUDDISTransactionHistory records
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         26/10/2015  //set DD account name to 255chars in case is longer than that
    ****************************************************************************************/
    public static void createAUDDISTransactionHistoryRecord(
        String TSNumber, SubscriptionsWebservices.DirectDebitInfo directDebitDetails, SubscriptionsWebservices.Payment paymentDetails) {

        if(directDebitDetails == null){
            return;
        }

        Account a = getAccountByTSNumber(TSNumber);
        if(a == null) {
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        boolean foundAuddisRef = false;
        for(MPP_Transaction_History__c rec : [Select AUDDIS_Ref__c from MPP_Transaction_History__c where Payment_status__c = 'Success' and Subscriber__c=:a.Id and DD_Transaction_Type__c = 'AUDDIS']) {
            if(rec.AUDDIS_Ref__c == directDebitDetails.auddisRef) {
                foundAuddisRef = true;
                break;
            }
        }

        // if Auddis Ref already exists for an Account then don't create new record
        if(!foundAuddisRef) {
            MPP_Transaction_History__c txn =
                new MPP_Transaction_History__c(DD_Transaction_Type__c = 'AUDDIS',
                                                DD_Account_Name__c = (directDebitDetails.accountName!=null ? directDebitDetails.accountName.LEFT(100) : directDebitDetails.accountName),
                                                DD_Account_Number__c = directDebitDetails.accountNumber,
                                                DD_Sort_Code__c = directDebitDetails.sortCode,
                                                Payment_status__c = 'Success',
                                                Subscriber__c = a.Id,
                                                AUDDIS_Ref__c = directDebitDetails.auddisRef,
                                                Payment_Submission_Date__c = directDebitDetails.submittedPaymentDate);
            if(paymentDetails != null) {
                txn.Order_ID__c = paymentDetails.orderId;
                txn.Digital_Subscription_ID__c = paymentDetails.digitalSubscriptionID;
            }

            try {
                insert txn;
            } catch(DmlException e) {
                handleSingleDMLException(e, txn);
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.6
    Function - Create a subscription method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/03/2015  //modified record type fetching as was throwing exceptions on deployment
    Wiktor Czykin   1.2         02/11/2015  //added low start check and fields population, simplified
    Michal Szewczyk 1.3         13/01/2016  //removed exception throw when no POC was found in SF
    Michal Szewczyk 1.4         13/01/2016  //remove fields from subscription initialization ( weekly price etc)
    Michal Szewczyk 1.5         17/06/2016  //change product on POC to default
    Wiktor Czykin   1.6         02/03/2017  //added record type id filter for TCode Product
    ****************************************************************************************/
    public static Id createSubscription(String TSNumber, String POC, String TCode, SubscriptionsWebservices.Subscription subscriptionDetails, SubscriptionsWebservices.MPPRecurringInfo recurringDetails,zqu__ZProduct__c selectedProd){
        if(subscriptionDetails == null || subscriptionDetails.productType == null || subscriptionDetails.productType.toLowerCase() != Constants.PRODUCT_PREMIUM.toLowerCase()) return null;
        validateSubscription(subscriptionDetails);
        //First we populate fields that we know
        Subscription__c subscription = new Subscription__c( RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName()),
                                                            Payment_Details_Received__c = true,
                                                            Delivery_Type__c = Constants.DELIVERYTYPE_OTC,
                                                            Subscription_Status__c = Constants.SSTATUS_PENDING,
                                                            Voucher_Pack_Duration__c = 13,
                                                            Order_Taken_Method__c = 'Online',
                                                            Order_Taken_Date__c = Date.today(),
                                                            Order_Taken_By_Company__c = 'TMG',
                                                            Order_Taken_By_User_Department__c = 'Online User',
                                                            Product__c = selectedProd.Id
                                                            );

        // Add last accessed
        List<Account> lstAccount = [SELECT      Id,
                                                Mobile_Last_Accessed__c,
                                                Tablet_Last_Accessed__c,
                                                Website_Last_Accessed__c,
                                                PersonMailingCountry
                                            FROM Account
                                            WHERE Subscriber_Number_Static__c = :TSNumber];
        if(lstAccount.isEmpty()) return null;
        Account subscriptionAccount = lstAccount[0];

        // Weekly price could come from POC or TCode
        String sTCodeSoql = 'select '+GlobalQueries.generateFieldsListForQuery(TCodeManagement__c.class.getName(), null, null)+' from TCodeManagement__c ';
        Id tCodeId;
        Id tCodeProdId;
        if(String.isNotBlank(POC)){
            List<POC__c> pocs = [SELECT Id, TCodeManagement__c,Product__c FROM POC__c WHERE POC_Id__c = :POC];
            if(!pocs.isEmpty()){
                tCodeId = pocs[0].TCodeManagement__c;
                tCodeProdId = selectedProd.Id;
                sTCodeSoql += ' where Id = :tCodeId';
            }else{
                sTCodeSoql += ' where Name = :TCode';
                tCodeProdId = selectedProd.Id;
            }
        }else{
            sTCodeSoql += ' where Name = :TCode';
            tCodeProdId = selectedProd.Id;
        }

        TCodeManagement__c tCodeRecord = null;
        TCode_Product__c tCodeProdRecord = null;
        List<TCodeManagement__c> lstTCode = Database.query(sTCodeSoql);
        if(!lstTCode.isEmpty()){
            tCodeRecord = lstTCode[0];
            Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
            List<TCode_Product__c> tmpTCodeProds = [select Id, Weekly_Price__c, Low_Start_Price__c from TCode_Product__c where TCodeManagement__c =:tCodeRecord.Id and Product__c =:tCodeProdId and RecordTypeId = :offerRecordTypeId limit 1];
            if(tmpTCodeProds.size()>0) {
               tCodeProdRecord = tmpTCodeProds[0];
            } else {
                throw new WebserviceUtil.NullParameterException('Unable to find TCode Product record.', '');
            }

        }else{
            throw new WebserviceUtil.NullParameterException('Unable to find TCode record.', '');
        }

        // Figure out the correct VAT rate
        VAT__c vatSettings = VAT__c.getInstance(Constants.VAT_SETTINGS_VAT);
        Decimal vatRate = GlobalQueries.getVATRateForCountry(vatSettings, Country_Codes__c.getInstance(subscriptionAccount.PersonMailingCountry));
        if(vatSettings == null || vatRate == null) throw new WebserviceUtil.GenericWSException('1', 'Unable to find transaction required settings.');

        Date sixMonthsInThePast = Date.today().addMonths(-6);
        subscription.Digital_VAT_Rate__c = vatRate;
        subscription.Order_Taken_Wave__c = tCodeRecord.Name;
        subscription.TCode__c = tCodeRecord.Id;
        subscription.Weekly_Price__c = tCodeProdRecord.Weekly_Price__c;
        subscription.Subscriber__c = subscriptionAccount.Id;
        subscription.WebsiteLastAccessed__c = subscriptionAccount.Website_Last_Accessed__c;
        subscription.Tablet_Last_Accessed__c = subscriptionAccount.Tablet_Last_Accessed__c;
        subscription.Mobile_Last_Accessed__c = subscriptionAccount.Mobile_Last_Accessed__c;

        setSubscriptionPaymentConfig(subscription, subscriptionDetails, recurringDetails);

        if(subscription.isContinuous__c && String.isNotBlank(tCodeRecord.Type__c) && tCodeRecord.Type__c == Constants.RECTYPE_SUBSCRIPTION_LOWSTART){
            setSubscriptionLowStartDetails(subscription, tCodeRecord,tCodeProdRecord);
        }

        setMPPSubscriptionFields(subscription, recurringDetails);

        try{
            insert subscription;
        } catch (DmlException e) {
            System.debug('Exception :'+e);
            handleSingleDMLException(e, subscription);
        }
        return subscription.Id;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - // Update a subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/11/2015  //added low start check and fields population, simplified
    Michal Szewczyk 1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    public static Id updateSubscription(String subscriptionId, SubscriptionsWebservices.Subscription subscriptionDetails, SubscriptionsWebservices.MPPRecurringInfo recurringDetails, Boolean hasPaymentDetailsReceived){
        //fetching of subscription related tCode information to check if low start payment schedule needs to be generated
        List<Subscription__c> lstSubscription = [select Id,
                                                        TCode__c,
                                                        TCode__r.Type__c,
                                                        TCode_Product__r.Weekly_Price__c,
                                                        TCode_Product__r.Low_Start_Price__c,
                                                        TCode__r.Low_Start_Period__c
                                                    from Subscription__c
                                                    where Id = :subscriptionId];
        if(lstSubscription.isEmpty()) throw new WebserviceUtil.GenericWSException('1', 'Cannot identify subscription that need update.');
        TCodeManagement__c tCode = lstSubscription[0].Tcode__r;
        TCode_Product__c tCodeProdRecord = lstSubscription[0].TCode_Product__r;

        Subscription__c subscription = new Subscription__c( Id = subscriptionId,
                                                            Payment_Details_Received__c = hasPaymentDetailsReceived,
                                                            Order_Taken_Method__c = 'Online Renewal',
                                                            Order_Taken_Date__c = Date.today()
        );

        setSubscriptionPaymentConfig(subscription, subscriptionDetails, recurringDetails);

        if(subscription.isContinuous__c && tCode != null && String.isNotBlank(tCode.Type__c) && tCode.Type__c == Constants.TCODE_TYPE_LOWSTART){
            setSubscriptionLowStartDetails(subscription, tCode,tCodeProdRecord);
        }

        setMPPSubscriptionFields(subscription, recurringDetails);

        try{
            update subscription;
        }catch(DmlException e) {
            System.debug('Exception :'+e);
            handleSingleDMLException(e, subscription);
        }
        return subscriptionId;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/12/2015
    Version - 1.0
    Function -  Extracted payment fields population to a common method as same code was executed both on create and update
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private static void setSubscriptionPaymentConfig(Subscription__c subscription, SubscriptionsWebservices.Subscription subscriptionDetails, SubscriptionsWebservices.MPPRecurringInfo recurringDetails){
        Boolean isContinuous = false;

        subscription.Start_Date__c = subscriptionDetails.startDate;
        if(subscriptionDetails != null) {
            subscription.Promo_Code__c = subscriptionDetails.promoCode;
            subscription.Promotion_Name__c = subscriptionDetails.promoName;
            subscription.Promo_Code_Expiry_Date__c = subscriptionDetails.promoValidToDate;
        }

        if(subscriptionDetails.paymentDate != null && recurringDetails.paymentType != null){
            //For 'creditdebitcard'/'credit card'
            if(recurringDetails.paymentType.toLowerCase().contains('card')){
                subscription.MPP_Scheduled_First_Payment_Date__c = subscriptionDetails.paymentDate;
                if(subscriptionDetails.subscriptionType != null && subscriptionDetails.subscriptionType.equalsIgnoreCase(Constants.KEY_CONTINUOUS)){
                    isContinuous = true;
                    subscription.MPP_CC_Frequency__c = recurringDetails.frequency;
                    if(subscriptionDetails.paymentDate.day()<5){
                        subscription.PaymentDate__c = '1';
                    }else{
                        subscription.PaymentDate__c = '15';
                    }
                }
            }else{//For 'directdebit'/'direct debit'
                isContinuous = true;
                subscription.MPP_DD_Frequency__c = recurringDetails.frequency;
                if(subscriptionDetails.paymentDate.day()<5){
                    subscription.PaymentDate__c = '1';
                }else{
                    subscription.PaymentDate__c = '15';
                }
                Date temp = subscriptionDetails.paymentDate;
                subscription.MPP_Scheduled_First_Payment_Date__c = Date.newInstance(temp.year(), temp.month(), Integer.valueOf(subscription.PaymentDate__c));
            }
        }

        subscription.isContinuous__c = isContinuous;
        subscription.Payment_Type__c = getReadblePaymentType(recurringDetails.paymentType);
        subscription.Subscription_Duration_Picklist__c = getSubscriptionDuration(subscriptionDetails.subscriptionType);
    }


    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/12/2015
    Version - 1.1
    Function -  Method to calculate low start payment schedule and related low start info.
                Unfortunatelly it is the only way to do it as we cannot get back parameters generated with CreateSession request back to salesforce.com.
                Also we cannot store and relate information that gets generated with CreateSession because online acquisition doesnt create records in sfdc only until payment is successfully completed.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         15/01/2016  //modified generatePaymentScheduleForLowStart() call
    Michal Szewczyk 1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    @TestVisible private static void setSubscriptionLowStartDetails(Subscription__c subscription, TCodeManagement__c tCode,TCode_Product__c tCodeProd){
        if( subscription == null || tCode == null || String.isBlank(tCode.Low_Start_Period__c) || !tCode.Low_Start_Period__c.isNumeric() || tCodeProd.Low_Start_Price__c == null || String.isBlank(subscription.Subscription_Duration_Picklist__c) ||!subscription.Subscription_Duration_Picklist__c.isNumeric()){
             throw new WebserviceUtil.GenericWSException('1', 'Cannot identify parameters for low start payment schedule calculation.');
        }

        subscription.Low_Start_Period__c = Integer.valueOf(tCode.Low_Start_Period__c);
        subscription.Low_Start_Weekly_Price__c = tCodeProd.Low_Start_Price__c;
        subscription.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());

        String sFrequency = '';
        if(subscription.Payment_Type__c == Constants.SUB_PMETHOD_CC){
            sFrequency = subscription.MPP_CC_Frequency__c;
        }else if(subscription.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            sFrequency = subscription.MPP_DD_Frequency__c;
        }
        try{
            MppUtil.PaymentSetupWrapper psw = MppUtil.generatePaymentScheduleForLowStart(   tCode,
                                                                                            tCodeProd,
                                                                                            Integer.valueOf(tcode.Low_Start_Period__c),
                                                                                            Integer.valueOf(subscription.Subscription_Duration_Picklist__c),
                                                                                            subscription.Start_Date__c.day()+'/'+subscription.Start_Date__c.month()+'/'+subscription.Start_Date__c.year(),
                                                                                            sFrequency,
                                                                                            Constants.MAP_PAYMENTTYPE_SUBSCRIPTION_TO_MPP.get(subscription.Payment_Type__c),
                                                                                            null,
                                                                                            null);
            subscription.put(Constants.MPP_IRREGULAR_PAYMENT_SCHEDULE_FIELD, JSON.serialize(psw));
        }catch(Exception e){
            throw new WebserviceUtil.GenericWSException('1', 'Payment schedule calculation error. '+e.getMessage());
        }
    }


    /** Get the value of the digital subscriber status field for a particular TSNumber
    */
    public static String checkDigitalSubscriberStatus(String TSNumber){

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }
        Account a = getAccountByTSNumber(TSNumber);
        if(a == null){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        return a.Subscriber_Digital_Status__c;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Used as a single point for sending error email from
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //made email custom settings based, removed old custom settings reference (EmailError__c)
    ****************************************************************************************/
    public static void sendErrorEmail(String method, String logId, String message, Exception thrownException){
        System.debug('***message: ' + message);
        System.debug('***thrownException: ' + thrownException);
        Boolean bMailCheck = Constants.WEBSERVICE_ERROR_NOTIFICATIONS_DEFAULT;

        General__c emailSetting = General__c.getInstance(Constants.GENERAL_WEBSERVICE_ERROR_NOTIFICATIONS);
        if(emailSetting != null){
            bMailCheck = emailSetting.Value_Boolean__c;
        }

        if(bMailCheck == true){
            General__c emailAddressSetting = General__c.getInstance(Constants.GENERAL_WEBSERVICE_ERROR_EMAIL);
            if(emailAddressSetting == null || String.isBlank(emailAddressSetting.Value__c)) return;

            TMGUtil.EmailUtil eml = new TMGUtil.EmailUtil(new List<String> {emailAddressSetting.Value__c});

            String body = 'An error occured in webservice method: ' + method + '\r\n\r\n';
            body += 'Returned error message: ' + message + '\r\n\r\n';
            body += 'Further exception details: ' + string.valueOf(thrownException) + '\r\n\r\n';
            body += 'Webservice Log: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + logId;

            eml.plainTextBody(body)
                .subject('SubscriptionsWebservice error')
                .replyTo(emailAddressSetting.Value__c)
                .senderDisplayName('Subscription Webservices')
                .build()
                .sendEmail();
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Get the list of incentives that are associated with a particular TCode, they will be product specific
                Notice that here we check the validity of the TCode where tcode passed in might have Valid__c field set to false. So webservice might successfully retu
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         03/09/2015  //modified method signature to use Tcode wrapper from SubscriptionsWebservices class.
                                            //modified the soql to use tcode Id instead of a name (as it was fetched by name already before it was passed into here)
                                            //modified the soql - removed the subscriptionType - so that incentives are selected based on new flags
    Wiktor Czykin   1.2         02/02/2016  //restored Subscription_Type__c to soql as still used by digital
    Michal Szewczyk 1.3         01/04/2016  //adjust method to use new data model
    Wiktor Czykin   1.4         02/03/2017  //added tcode product record type filter
    ****************************************************************************************/
    public static List<SubscriptionsWebservices.Incentive> getIncentives(String productId, SubscriptionsWebservices.Tcode tCodeWrapper, String subscriptionType){

        List<SubscriptionsWebservices.Incentive> incentives = new List<SubscriptionsWebservices.Incentive>();
        Set<Id> setIncentiveIds = new Set<Id>();

        if(productId == null){
            throw new WebserviceUtil.NullParameterException('productId', '');
        }
        if(tCodeWrapper == null || tCodeWrapper.tCodeRecord == null || tCodeWrapper.tCodeRecord.Id == null){
            throw new WebserviceUtil.NullParameterException('TCode', '');
        }
        if(subscriptionType == null){
            throw new WebserviceUtil.NullParameterException('subscriptionType', '');
        }
        if(!isValidProductType(productId)){
            throw new WebserviceUtil.InvalidFieldException('productId', productId, productId + '');
        }

        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        TCodeManagement__c tcode = tCodeWrapper.tCodeRecord;
        for(TCode_Product_Incentive__c item : [SELECT    Id,
                                                Incentive__c,
                                                TCode_Product__r.Product__c,
                                                Incentive__r.Incentive_Description__c,
                                                Incentive__r.Image_Url__c,
                                                Subscription_Type__c
                                            FROM TCode_Product_Incentive__c
                                            WHERE TCode_Product__r.Product__c = :productId
                                            AND TCode_Product__r.TCodeManagement__c = :tCodeWrapper.tCodeRecord.Id
                                            AND TCode_Product__r.RecordTypeId = :offerRecordTypeId
                                            AND TCode_Product__r.TCodeManagement__r.Valid__c = true
                                            AND (Incentive__r.Valid_To__c = null OR Incentive__r.Valid_To__c >= TODAY)
                                            AND (Incentive__r.Valid_From__c = null OR Incentive__r.Valid_From__c <= TODAY)]){
            if(!setIncentiveIds.contains(item.Incentive__c)){
                Set<String> setApplicability = new Set<String>(getSubscriptionTypesForTCodeIncentive(item));
                if(!setApplicability.contains(subscriptionType)) continue;

                setIncentiveIds.add(item.Incentive__c);
                SubscriptionsWebservices.Incentive incentive = new SubscriptionsWebservices.Incentive();
                incentive.Id = item.Incentive__c;
                incentive.Description = item.Incentive__r.Incentive_Description__c;
                incentive.ImageUrl = item.Incentive__r.Image_Url__c;
                incentives.add(incentive);
            }
        }
        return incentives;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Tcode fetching method based on conditions.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         03/09/2015  //changed the call to getTCodeDetails
    Lynette Lim     1.2         28/04/2016  //modified to accomodate TCODE retrieval from the POC record
    ****************************************************************************************/
    public static SubscriptionsWebservices.Tcode getTCodeNewImpl(String POC, String flowType, String tCodeVal){
        System.debug('**** - getTCodeNewImpl called with following values. POC: ' + POC + ' - flowType: ' + flowType + ' - tCodeVal: ' + tCodeVal);
        Boolean isNotBlankTCode = String.isNotBlank(tCodeVal);
        SubscriptionsWebservices.Tcode tCode;

        // The below conditions are kept for regression
        flowType = flowType.toLowerCase();
        if(!isValidFlowType(flowType)){
            throw new WebserviceUtil.InvalidFieldException('flowType', flowType, flowTypes + '');
        }
        if(flowType == 'pocflow' && (POC == null || POC.trim().length() == 0)){
            throw new WebserviceUtil.NullParameterException('POC', '');
        }
        if(flowType == 'promotionflow' && ((TCode == null && isNotBlankTCode) || tCodeVal.trim().length() == 0)){
            System.debug('**** - returning from Condition 3');
        }
        if(flowType == 'pocflow' && (TCode == null && isNotBlankTCode == false)){
            return SubscriptionsWebservicesHandlers.getTCodeForPOC(POC);
        }

        // If above conditions do not fire and we have a tcode, then use getTCodeDetails
        if (TCode == null && isNotBlankTCode && tCodeVal != 'null'){
            return SubscriptionsWebservicesHandlers.getTCodeDetails(new Set<String>{'Name = \''+String.escapeSingleQuotes(tCodeVal)+'\''});
        }

        // If none of the above conditions fire, then use Open Offer details
        return SubscriptionsWebservicesHandlers.getOpenOfferTCode();
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  Amended as part of the Vodafone Implementation. getTCode now receives the same values as previously,
                but returns results in the TCode Object format defined in Subscription Webservices
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static SubscriptionsWebservices.Tcode getTCode(String POC, String flowType, String tCodeVal){
        SubscriptionsWebservices.Tcode tCode;
        flowType = flowType.toLowerCase();
        if(!isValidFlowType(flowType)){
            throw new WebserviceUtil.InvalidFieldException('flowType', flowType, flowTypes + '');
        }
        if(flowType == 'pocflow' && (POC == null || POC.trim().length() == 0)){
            throw new WebserviceUtil.NullParameterException('POC', '');
        }
        if(flowType == 'promotionflow' && (TCode == null || tCodeVal.trim().length() == 0)){
            throw new WebserviceUtil.NullParameterException('TCode', '');
        }
        if(flowType == 'pocflow'){
            return SubscriptionsWebservicesHandlers.getTCodeForPOC(POC);
        }

        if(flowType == 'openofferflow'){
            if((tCode == null || tCodeVal.trim().length() == 0))
                return SubscriptionsWebservicesHandlers.getOpenOfferTCode();
        }

        if(flowType == 'promotionflow'){
            return tCode;
        }
        return tCode;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Find the TCode associated with a POC
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         03/09/2015  //changed so that it uses common tcode fetching method
    ****************************************************************************************/
    @TestVisible
    private static SubscriptionsWebservices.Tcode getTCodeForPOC(String POC){
        SubscriptionsWebservices.Tcode tCode;

        List<POC__c> pocs = [SELECT TCodeManagement__r.Name FROM POC__c WHERE POC_Id__c = :POC];
        if(!pocs.isEmpty() && pocs[0].TCodeManagement__r.Name != null){
            tCode = getTCodeDetails(new Set<String>{'Name = \''+String.escapeSingleQuotes(pocs[0].TCodeManagement__r.Name)+'\''});
        }else{
            Id logId = TMGUtil.logWebServiceRequest('Inbound', null, 'getTCodeForPOC', new map<String, Object>{'POC' => POC});
        }
        return tCode;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Find the default TCode
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //changed so that it only calls common tcode fetching method with proper params
    ****************************************************************************************/
    public static SubscriptionsWebservices.Tcode getOpenOfferTCode(){
        return getTCodeDetails(new Set<String>  {   'Type__c = \''+Constants.TCODE_TYPE_OPENOFFER+'\'',
                                                    'Valid__c = true'
                                                }
                                );
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - retrieve all TCode information for a given code
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //fixed so that 'no rows for assignment' exception is not thrown,
                                            //changed to be a common method fetching tcodes and populating wrapper, uses GlobalQueries so
    ****************************************************************************************/
    public static SubscriptionsWebservices.Tcode getTCodeDetails(Set<String> setConditions){
        // this class assumes that the tCode Name being passed in is valid. Any checks required to validate TCode must be done prior to calling this class
        if(setConditions == null || setConditions.isEmpty()) throw new WebserviceUtil.NullParameterException('TCode', '');

        String sSoql = 'select ' + GlobalQueries.generateFieldsListForQuery(TCodeManagement__c.class.getName(), null, null) + ' from  TCodeManagement__c ';
        sSoql += 'where '+ String.join(new List<String>(setConditions), ' and ') + ' limit 1';

        List<TCodeManagement__c> lstTCodes = Database.query(sSoql);

        if(lstTCodes.isEmpty()) return null;

        TCodeManagement__c tCode = lstTCodes[0];

        SubscriptionsWebservices.Tcode tCodeWrapper = new SubscriptionsWebservices.Tcode(tCode.Name);
        tCodeWrapper.tCodeRecord = tCode;
        tCodeWrapper.gpStageOneDuration = Integer.valueOf(tCode.Gp_Stage_One_Duration__c);
        tCodeWrapper.gpStageTwoDuration = Integer.valueOf(tCode.Gp_Stage_Two_Duration__c);
        tCodeWrapper.partnerCCenterEmail = tCode.Partner_Contact_Center_Email__c;
        tCodeWrapper.partnerCCenterNumber = tCode.Partner_Contact_Center_Tel__c;
        tCodeWrapper.partnerName = tCode.Partner_Name__c;
        tCodeWrapper.promoName = tCode.Description__c;
        tCodeWrapper.promoType = tCode.Type__c;
        tCodeWrapper.tAndCURL = tCode.tandcURL__c;
        return tCodeWrapper;
    }

    //MIrfan@Appirio 17Feb12
    public static Decimal calculateSavingOnCoverPrice(Decimal coverPrice, Decimal weeklyPrice,Integer weeks){
        if(!TMGUtil.isDataValid(coverPrice) || !TMGUtil.isDataValid(weeklyPrice) || !TMGUtil.isDataValid(weeks))
            return null;
        return (((coverPrice-weeklyPrice)/coverPrice)*100).setScale(2);
    }

    //MIrfan@Appirio 10Feb12
    public static SubscriptionsWebservices.RenewalOffer getRenewalOffer(String tsNumber){
        SubscriptionsWebservices.RenewalOffer result = new SubscriptionsWebservices.RenewalOffer();
        if(!TMGUtil.isDataValid(tsNumber)){
            result.wsError = new WebserviceUtil.WSError('','Invalid TSNumber: ('+tsNumber+').');
            return result;
        }


        Subscription__c subRenewal;
        for(Subscription__c sub: [Select Start_Date__c,Subscription_Status__c,  Subscriber__r.subscriber_number_static__c,
                Subscriber__c, Previous_Subscription__c, Id,Previous_Subscription__r.Subscription_Status__c,
                Subscriber__r.PersonMailingPostalCode, Weekly_Price__c, Total_Price__c, Subscriber__r.Wave_ID__c,
                Subscriber__r.POC__c,Subscription_Duration_Number__c, IsContinuous__c, Subscriber__r.Cover_Price__c,
                Previous_Subscription__r.Subscription_Duration_Number__c
                From Subscription__c s
                where Previous_Subscription__c !=null and
                Previous_Subscription__r.Subscription_Status__c in ('In Renewal','Lapsed') and
                Subscription_Status__c='Offered' and Subscriber__r.subscriber_number_static__c =:tsNumber
                order by createddate desc limit 1]){
            subRenewal=sub;
        }

        try{
            if(subRenewal!=null){

                //Map<string, List<SubscriptionsWebservices.Incentive>> mapTCodes = getOfferIncentives(subRenewal.Subscriber__r.Wave_ID__c,'Premium');
                SubscriptionsWebservices.ProductOffer offer;
                Decimal duration = subRenewal.Subscription_Duration_Number__c;
                Decimal prevSubDuration = subRenewal.Previous_Subscription__r.Subscription_Duration_Number__c;
                result.offeredSubId=subRenewal.id;
                result.SubscriptionStartDate=subRenewal.Start_Date__c;

                Decimal coverPrice = subRenewal.Subscriber__r.Cover_Price__c;
                Decimal weeklyPrice = subRenewal.Weekly_Price__c;

                result.coverPrice = String.valueOf(coverPrice);

                    //Add for 26 weeks
                    if(prevSubDuration<52){
                        offer = new SubscriptionsWebservices.ProductOffer();
                        offer.productName = '26 weeks';
                        offer.weeklyPrice = weeklyPrice;
                        offer.totalPrice = 100*subRenewal.Weekly_Price__c * 26;//return amount in pence
                        offer.duration = '26';
                        offer.productType='premium_26weeks';

                        if(TMGUtil.isDataValid(coverPrice) && TMGUtil.isDataValid(weeklyPrice))
                        {
                            offer.savingPercentageOnCoverPrice = calculateSavingOnCoverPrice(coverPrice,weeklyPrice,26);
                            offer.savingAmountOnCoverPrice =(coverPrice*26)-(weeklyPrice*26);
                        }

                        result.products.add(offer);
                    }

                    //Add for 52 weeks
                    offer = new SubscriptionsWebservices.ProductOffer();
                    offer.productName = '52 weeks';
                    offer.weeklyPrice = subRenewal.Weekly_Price__c;
                    offer.totalPrice = 100*subRenewal.Weekly_Price__c * 52;//return amount in pence for 52 weeks/Annual
                    offer.duration = '52';
                    offer.productType='premium_52weeks';
                    if(TMGUtil.isDataValid(coverPrice) && TMGUtil.isDataValid(weeklyPrice))
                    {
                        offer.savingPercentageOnCoverPrice = calculateSavingOnCoverPrice(coverPrice,weeklyPrice,52);
                        offer.savingAmountOnCoverPrice =(coverPrice*52)-(weeklyPrice*52);
                    }
                    result.products.add(offer);

                    //Add continuous monthly
                    offer = new SubscriptionsWebservices.ProductOffer();
                    offer.productName = 'Continuous';
                    offer.weeklyPrice = subRenewal.Weekly_Price__c;

                    Double FullAmount = 52 * subRenewal.Weekly_Price__c;
                    Decimal OneMonthRounded = (FullAmount / 12) - 0.005;
                    OneMonthRounded = OneMonthRounded.setScale(2);
                    offer.monthlyPrice = FullAmount - (OneMonthRounded * 11 );//Monthly price

                    offer.duration = '52';//String.valueOf(duration);
                    offer.productType='premium_continuous';
                    offer.totalPrice = 100*offer.weeklyPrice*52;//return amount in pence for 52 weeks/Annual
                    offer.savingPercentageOnCoverPrice = 0; //Saving will be zero for Continuous monthly as charged weekly.
                    offer.savingAmountOnCoverPrice =0;
                    result.products.add(offer);

            }else{
                result.wsError = new WebserviceUtil.WSError('','No Renewal Subscription found for ('+tsNumber+').');
            }
        }catch(Exception ex){result.wsError = new WebserviceUtil.WSError('',ex.getMessage()+ ' for ('+tsNumber+').');}
        return result;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.7
    Function - Validate a POC matches the given postcode and is in date
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/08/2015  //added support of new data model(both TCode and TCodeIncentives), added constants, removed exception driven logic
    Michal Szewczyk 1.2         14/03/2016  //replaced payment checkboxes with multipick list Payment_Type
    Michal Szewczyk 1.3         04/04/2016  //adjust method to use new data model
    Wiktor Czykin   1.4         27/05/2016  //default product support for online POC
    Michal Szewczyk 1.5         17/06/2016  //added related field to TCode_Product__c query
    Wiktor Czykin   1.6         20/06/2016  //modified parameter passed as one of pricing option identifiers to GlobalQueries for Premium options (product id rather than PREMIUM string)
    Wiktor Czykin   1.7         03/03/2017  //added record type condition for tcode product filter
    ****************************************************************************************/
    public static SubscriptionsWebservices.POCDetails getPOCStatus(String POC, String postCode){
        SubscriptionsWebservices.POCDetails result = new SubscriptionsWebservices.POCDetails();
        result.POCStatus = 'DoesntExist';
        List<POC__c> pocs = [Select ExpiryDate__c,
                                    TCodeManagement__c,
                                    TCodeManagement__r.Name,
                                    TCodeManagement__r.Price__c,
                                    TCodeManagement__r.Digital_Monthly_Price__c,
                                    TCodeManagement__r.Digital_Yearly_Price__c,
                                    TCodeManagement__r.AllowContinuous__c,
                                    TCodeManagement__r.Is_52_Continuous__c,
                                    TCodeManagement__r.X13_week_price__c,
                                    TCodeManagement__r.Payment_Type__c,
                                    Product__c,
                                    Product__r.Print_Product__c
                                From POC__c
                                Where POC_Id__c = :POC
                                And PostalCode__c = :SubscriberPortal.FormatPostCode(postCode)];

        if(pocs.isEmpty()) return result;
        POC__c pocRecord = pocs[0];
        result.TCode = pocRecord.TCodeManagement__r.Name;
        TCode_Product__c tCodeProdRecord;
        Id productId = pocRecord.Product__c;
        if(productId == null){
            General__c defaultProduct = General__c.getValues(Constants.GENERAL_DEFAULT_PRODUCT_ID);
            if(defaultProduct != null && String.isNotBlank(defaultProduct.Value__c)){
                try{
                    productId = (Id) defaultProduct.Value__c;
                }catch(Exception e){
                    System.debug('TMGLOG::getPOCStatus::Invalid id for default product silent fail.');
                    return result;
                }
            }
        }

        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        List<TCode_Product__c> relatedTCodeProd = [select   Id,
                                                            TCodeManagement__c,
                                                            X13_Week_Price__c,
                                                            Weekly_Price__c,
                                                            Digital_Monthly_Price__c,
                                                            Digital_Yearly_Price__c,
                                                            TCodeManagement__r.Payment_Type__c,
                                                            TCodeManagement__r.Is_52_Continuous__c
                                                    from TCode_Product__c
                                                    where Product__c =:productId
                                                    and RecordTypeId = :offerRecordTypeId
                                                    and TCodeManagement__c =:pocRecord.TCodeManagement__c];

        if(relatedTCodeProd.isEmpty()){
            throw new WebserviceUtil.GenericWSException('1','No TCode Product Record found');
        }else {
            tCodeProdRecord = relatedTCodeProd[0];
        }
        if(pocRecord.ExpiryDate__c  == null || pocRecord.ExpiryDate__c >= Date.today()){
            result.POCStatus = 'Valid';
        } else{
            result.POCStatus = 'Expired';
        }

        // There will always be one set of prices - with no incentives
        Map<String, SubscriptionsWebservices.SubPrice> priceWrk = new Map<String, SubscriptionsWebservices.SubPrice>();
        SubscriptionsWebservices.SubPrice price = new SubscriptionsWebservices.SubPrice();

        if(TMGUtil.isDataValid(tCodeProdRecord.Weekly_Price__c)){
            if(pocRecord.TCodeManagement__r.Is_52_Continuous__c){
                //price.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
                price.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
                price.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS.toLowerCase();
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                Pricing_Options__c productPricingOption = GlobalQueries.getPricingOptions(productId, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
                if(productPricingOption != null){
                    price.price = productPricingOption.Dynamic_Price__c;
                }else{
                    price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
                }
                priceWrk.put(price.productType + price.subscriptionType, price);
            }
            //until SAM issue is fix add 13 weeks to SAM call
            //if(pocRecord.TCodeManagement__r.Allow13Week__c){
                price = new SubscriptionsWebservices.SubPrice();
                price.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
                price.subscriptionType = Constants.SUBSCRIPTIONTYPE_13WEEKS;
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                Pricing_Options__c productPricingOptions = GlobalQueries.getPricingOptions(productId, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
                if(productPricingOptions != null){
                    price.price = productPricingOptions.Dynamic_Price__c;
                }else{
                    price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
                }
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                priceWrk.put(price.productType + price.subscriptionType, price);
            //}

            if(TMGUtil.multiPickListSelectionCheck(pocRecord.TCodeManagement__r.Payment_Type__c,Constants.ALLOW_ONE_OFF_26_WEEK)){
                price = new SubscriptionsWebservices.SubPrice();
                price.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
                price.subscriptionType = Constants.SUBSCRIPTIONTYPE_26WEEKS;
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                Pricing_Options__c productPricingOption = GlobalQueries.getPricingOptions(productId, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
                if(productPricingOption != null){
                    price.price = productPricingOption.Dynamic_Price__c;
                }else{
                    price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
                }
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                priceWrk.put(price.productType + price.subscriptionType, price);
            }

            if(TMGUtil.multiPickListSelectionCheck(pocRecord.TCodeManagement__r.Payment_Type__c,Constants.ALLOW_ONE_OFF_52_WEEK)){
                price = new SubscriptionsWebservices.SubPrice();
                price.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
                price.subscriptionType = Constants.SUBSCRIPTIONTYPE_52WEEKS;
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                Pricing_Options__c productPricingOption = GlobalQueries.getPricingOptions(productId, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
                if(productPricingOption != null){
                    price.price = productPricingOption.Dynamic_Price__c;
                }else{
                    price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
                }
                price.incentives = new List<SubscriptionsWebservices.Incentive>();
                priceWrk.put(price.productType + price.subscriptionType, price);
            }
        }

        if(TMGUtil.isDataValid(tCodeProdRecord.Digital_Monthly_Price__c)){
            price = new SubscriptionsWebservices.SubPrice();
            price.productType = Constants.PRODUCT_DIGITAL.toLowerCase();
            price.subscriptionType = Constants.SUBSCRIPTIONTYPE_MONTHLY;
            price.incentives = new List<SubscriptionsWebservices.Incentive>();
            Pricing_Options__c productPricingOption = GlobalQueries.getPricingOptions(price.productType, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
            if(productPricingOption != null){
                price.price = productPricingOption.Dynamic_Price__c;
            }else{
                price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
            }
            price.incentives = new List<SubscriptionsWebservices.Incentive>();
            priceWrk.put(price.productType + price.subscriptionType, price);
        }

        if(TMGUtil.isDataValid(tCodeProdRecord.Digital_Yearly_Price__c)){
            price = new SubscriptionsWebservices.SubPrice();
            price.productType = Constants.PRODUCT_DIGITAL.toLowerCase();
            price.subscriptionType = Constants.SUBSCRIPTIONTYPE_YEARLY;
            price.incentives = new List<SubscriptionsWebservices.Incentive>();
            Pricing_Options__c productPricingOption = GlobalQueries.getPricingOptions(price.productType, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
            if(productPricingOption != null){
                price.price = productPricingOption.Dynamic_Price__c;
            }else{
                price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
            }
            price.incentives = new List<SubscriptionsWebservices.Incentive>();
            priceWrk.put(price.productType + price.subscriptionType, price);
        }
        //fetch valid incentives related to TCode related to the POC
        for(TCode_Product_Incentive__c junction : [SELECT    Id,
                                                Incentive__c,
                                                TCode_Product__r.Product__c,
                                                Incentive__r.Incentive_Description__c,
                                                Incentive__r.Image_Url__c,
                                                Subscription_Type__c
                                            FROM TCode_Product_Incentive__c
                                                WHERE TCode_Product__r.TCodeManagement__r.Name = :pocRecord.TCodeManagement__r.Name
                                                AND (Incentive__r.Valid_From__c = null OR Incentive__r.Valid_From__c <= today)
                                                AND (Incentive__r.Valid_To__c = null OR Incentive__r.Valid_To__c >= today)]){
            List<String> lstSubscriptionTypes = getSubscriptionTypesForTCodeIncentive(junction);
            if(lstSubscriptionTypes.isEmpty()) continue;

            //in theory still contains soql in a loop
            for(String sType : lstSubscriptionTypes){
                String key = junction.TCode_Product__r.Product__c;
                if(!priceWrk.containsKey(key)){
                    price = new SubscriptionsWebservices.SubPrice();
                    price.productType = junction.TCode_Product__r.Product__c;
                    price.subscriptionType = sType;
                    Pricing_Options__c productPricingOption = GlobalQueries.getPricingOptions(price.productType, Constants.PRICINGOPTION_FLOWTYPE_POC, price.subscriptionType, result.TCode);
                    if(productPricingOption != null){
                        price.price = productPricingOption.Dynamic_Price__c;
                    }else{
                        price.price = getPriceInPence(tCodeProdRecord, price.productType, price.subscriptionType);
                    }
                    price.incentives = new List<SubscriptionsWebservices.Incentive>();
                    priceWrk.put(key, price);
                }
                SubscriptionsWebservices.Incentive incentive = new SubscriptionsWebservices.Incentive();
                incentive.Id = junction.Incentive__c;
                incentive.Description = junction.Incentive__r.Incentive_Description__c;
                incentive.ImageUrl = junction.Incentive__r.Image_Url__c;
                priceWrk.get(key).incentives.add(incentive);
            }
        }
        result.prices = new List<SubscriptionsWebservices.SubPrice>();
        result.prices = priceWrk.values();
        return result;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 27/08/2015
    Version - 1.0
    Function - Map premium incentives checkboxes to premium subscription types
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static List<String> getSubscriptionTypesForTCodeIncentive(TCode_Product_Incentive__c tcpi){
        List<String> lstSubscriptionTypes = new List<String>();

        if(TMGUtil.multiPickListSelectionCheck(tcpi.Subscription_Type__c,Constants.ONE_OFF_13_WEEK_APPLICABLE)){
            lstSubscriptionTypes.add(Constants.SUBSCRIPTIONTYPE_13WEEKS);
        }
        if(TMGUtil.multiPickListSelectionCheck(tcpi.Subscription_Type__c,Constants.ONE_OFF_26_WEEK_APPLICABLE)){
            lstSubscriptionTypes.add(Constants.SUBSCRIPTIONTYPE_26WEEKS);
        }
        if(TMGUtil.multiPickListSelectionCheck(tcpi.Subscription_Type__c,Constants.ONE_OFF_52_WEEK_APPLICABLE)){
            lstSubscriptionTypes.add(Constants.SUBSCRIPTIONTYPE_52WEEKS);
        }
        if(TMGUtil.multiPickListSelectionCheck(tcpi.Subscription_Type__c,Constants.CONTINUOUS_52_WEEK_APPLICABLE)){
            lstSubscriptionTypes.add(Constants.SUBSCRIPTIONTYPE_CONTINUOUS);
        }
        //digital ( not equal isPrint )
        if(!TMGUtil.productIsPrint(tcpi.TCode_Product__r.Product__c)){
            lstSubscriptionTypes.add(Constants.PRODUCT_DIGITAL);
        }
        return lstSubscriptionTypes;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Get the total price for the subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/08/2015  //added handling for 13 weeks one off, moved getWeeklyPrice method result here as made no sense to have separate method
    Michal Szewczyk 1.2         05/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    private static integer getPriceInPence(TCode_Product__c tcodeProd, String product, String subscriptionType){
        Decimal price = 0;
        if(product == Constants.PRODUCT_PREMIUM.toLowerCase()){
            if(subscriptionType == Constants.SUBSCRIPTIONTYPE_13WEEKS)
                price = tcodeProd.X13_week_price__c != null ? tcodeProd.X13_week_price__c: Constants.DEFAULT_13WEEK_PRICE;
            else if(subscriptionType == Constants.SUBSCRIPTIONTYPE_26WEEKS)
                price = tcodeProd.Weekly_Price__c * Constants.MAP_SUBSCRIPTIONTYPE_LENGTH.get(subscriptionType);
            else if(subscriptionType == Constants.SUBSCRIPTIONTYPE_52WEEKS)
                price = tcodeProd.Weekly_Price__c * Constants.MAP_SUBSCRIPTIONTYPE_LENGTH.get(subscriptionType);
            else if(subscriptionType == Constants.SUBSCRIPTIONTYPE_CONTINUOUS)
                price = tcodeProd.Weekly_Price__c;

        }else if(product == Constants.PRODUCT_DIGITAL.toLowerCase()){
            if(subscriptionType == Constants.SUBSCRIPTIONTYPE_MONTHLY)
                price = (TMGUTil.isDataValid(tcodeProd.Digital_Monthly_Price__c) ? tcodeProd.Digital_Monthly_Price__c : 0);
            else if(subscriptionType == Constants.SUBSCRIPTIONTYPE_YEARLY)
                price = (TMGUTil.isDataValid(tcodeProd.Digital_Yearly_Price__c) ? tcodeProd.Digital_Yearly_Price__c : 0);
        }
        return Integer.valueOf(price * 100);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Delete the POC based on POC_Id__c
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/08/2015  //not much really
    ****************************************************************************************/
    public static void deletePOC(String sPocId){
        if(String.isBlank(sPocId)){
            return;
        }
        List<POC__c> lstPocs = [SELECT Id FROM POC__c WHERE POC_Id__c = :sPocId];
        if(!lstPocs.isEmpty()){
            delete lstPocs;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - returns duration based on subscription type
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/08/2015  //changed to use constants
    ****************************************************************************************/
    private static String getSubscriptionDuration(String subscriptionType){
        String input = subscriptionType.toLowerCase();
        if(Constants.MAP_SUBSCRIPTIONTYPE_LENGTH.containsKey(input)){
            return Constants.MAP_SUBSCRIPTIONTYPE_LENGTH.get(input)+'';
        }
        return Constants.SUBSCRIPTION_DEFAULT_LENGTH+'';
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - returns duration based on subscription type
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/08/2015  //changed to use constants
    ****************************************************************************************/
    private static string getReadblePaymentType(String paymentType){
        String input = paymentType.toLowerCase();
        if(input == Constants.SAM_CREDITDEBITCARD){
            return Constants.SUB_PMETHOD_CC;
        }else if(input == Constants.SAM_DIRECTDEBIT){
            return Constants.SUB_PMETHOD_DD;
        }
        return paymentType;
    }

    // Make sure the start date is valid - if not return the next possible
    public static Date validateStartDate(Date startDate){
        Date firstValidDate;
        // Must be a Monday
        startDate = startDate.toStartOfWeek();
        // Make sure that it's at least the earliest startdate
        if(getWeekday(date.today()) < 4){
            firstValidDate = date.today().toStartOfWeek().addDays(14);
        } else{
            firstValidDate = date.today().toStartOfWeek().addDays(21);
        }

        if(startDate < firstValidDate){
            startDate = firstValidDate;
        }

        return startDate;
    }

    // Update the details of the last time a digital source was accessedby a particular subscriber
    public static void updateLastAccessedData(String TSNumber, String device, DateTime lastAccessed){

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        if(device == null){
            throw new WebserviceUtil.NullParameterException('device', '');
        }
        if(!devices.contains(device.toLowerCase())){
            throw new WebserviceUtil.InvalidFieldException('device', device, devices + '');
        }

        if(lastAccessed == null){
            throw new WebserviceUtil.NullParameterException('lastAccessed', '');
        }

        Map<string, Map<string,DateTime>> data = new Map<string, Map<string,DateTime>>();

        List<Account> updateAccounts = new List<Account>();

        for(Account acc : [SELECT Id,Subscriber_Digital_Status__c,Subscription_Status__c,RecordTypeId,MPP_Digital_Payment_Id__c,Number_of_Active_Subscriptions__c,Number_of_In_Renewal_Subscription__c,Number_of_Pending_Subscriptions__c,Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber]){

           //Added Change for PP-1271
           //last_accessed will be only updated for 'Active' state
           if(acc.Subscriber_Digital_Status__c=='Active')
           {
            if(device == 'website'){
                if(acc.Website_First_Accessed__c == null)
                    acc.Website_First_Accessed__c = lastAccessed;
                acc.Website_Last_Accessed__c = lastAccessed;
            }
            if(device == 'tablet'){
                if(acc.Tablet_First_Accessed__c == null)
                    acc.Tablet_First_Accessed__c = lastAccessed;
                acc.Tablet_Last_Accessed__c = lastAccessed;
            }
            if(device == 'mobile'){
                if(acc.Mobile_First_Accessed__c == null)
                    acc.Mobile_First_Accessed__c = lastAccessed;
                acc.Mobile_Last_Accessed__c = lastAccessed;
            }
            updateAccounts.add(acc);
           }

           // HYGIENE - DM 23-07-2013 - This is horrible code but implementing this quick and dirty fix to ensure that Print Subs will have accessed data updated too
           if(acc.Subscription_Status__c=='Active' && acc.Subscriber_Digital_Status__c!='Active')
           {
            if(device == 'website'){
                if(acc.Website_First_Accessed__c == null)
                    acc.Website_First_Accessed__c = lastAccessed;
                acc.Website_Last_Accessed__c = lastAccessed;
            }
            if(device == 'tablet'){
                if(acc.Tablet_First_Accessed__c == null)
                    acc.Tablet_First_Accessed__c = lastAccessed;
                acc.Tablet_Last_Accessed__c = lastAccessed;
            }
            if(device == 'mobile'){
                if(acc.Mobile_First_Accessed__c == null)
                    acc.Mobile_First_Accessed__c = lastAccessed;
                acc.Mobile_Last_Accessed__c = lastAccessed;
            }
            updateAccounts.add(acc);
           }


        }
        if(updateAccounts.size()>0)
         update updateAccounts;
    }


    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
	Description:
		Called when notification is received that the DD wasn't setup for a user
        Update the subscription status
        Create a task for the CSP
    ****************************************************************************************/
    public static void DDSetupFailure(String TSNumber, String failureReason, String failureCode){
        SubscriptionsWebservices.Subscriber subscriber =  new SubscriptionsWebservices.Subscriber();
        subscriber.TSNumber = TSNumber;
        DDsetupFailure(subscriber, failureReason, failureCode, null);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
	Description:
		Called when notification is received that the DD wasn't setup for a user Update the subscription status
		Create a task for the CSP
		Method accepts now SubscriptionsWebservices.Subscriber as argument instead of TSNumber
    #############Change Log#############
    Modified by    		Version     Change Date
	Pawel Chrzanowski	1.1			03/03/2016	//BACS failure shouldn't cause immediate change of setting to Inactive
    ****************************************************************************************/
    public static void DDSetupFailure(SubscriptionsWebservices.Subscriber Subscriberdetails, String failureReason, String failureCode,SubscriptionsWebservices.Payment Paymentdetails){

       //Changes Made to Retrieve TSNumber from Subscriberdetails
        String TSNumber;
        if(Subscriberdetails != null){
            TSNumber=Subscriberdetails.TSNumber;

        }

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }
        if(failureReason == null){
            throw new WebserviceUtil.NullParameterException('FailureReason', '');
        }

        String errorDesc = 'Failure Reason: ' + failureReason + '\nFailure Code: ' + failureCode;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c, RecordTypeId FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        if(accs == null || accs.size() == 0){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        List<MPP_Transaction_History__c> txns = [SELECT Id, Payment_Status__c FROM MPP_Transaction_History__c WHERE Subscriber__c = :accs[0].Id AND DD_Transaction_Type__c = 'AUDDIS' ORDER BY CreatedDate DESC];
        if(txns != null && txns.size() > 0){
            txns[0].Payment_Status__c = 'Failed';
            try{
                update txns[0];
            } catch(DMLException ex){
                handleSingleDMLException(ex, txns[0]);
            }
        }

        // Get the user for the task
        List<User> users = [SELECT Id FROM User WHERE name ='System'];
        User taskAssignee;
        if(users != null && users.size() > 0)
            taskAssignee = users[0];

        // Premium and digital need different fields updating
        List<Subscription__c> subs = new List<Subscription__c>();
        if(accs[0].RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())){

            /* check if premiumSub id is available in payment details
            * if yes, then it should participate in fetching the exact subscription along with the account id
            */
            if(Paymentdetails != null && paymentDetails.recurringDetails != null && Paymentdetails.recurringDetails.premiumSubscriptionID != null) {
                String premiumSubId = paymentDetails.recurringDetails.premiumSubscriptionID;
                //Changed in SOQL query
                subs = [SELECT Id, Subscription_Status__c, Cancellation_Date__c, Start_Date__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber
                AND Subscription_Status__c IN('Pending', 'Active', 'Pending Cancellation') AND MPP_Premium_Subscription_ID__c = :premiumSubId
                ORDER BY Start_Date__c DESC];

            } else {
                subs = [SELECT Id, Subscription_Status__c, Cancellation_Date__c, Start_Date__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber
                AND Subscription_Status__c IN('Pending', 'Active', 'Pending Cancellation') ORDER BY Start_Date__c DESC];
            }

            if(subs == null || subs.size() == 0){
                return;
            }

            moveSubToPendingCancellation(subs[0], failureReason, 'AUDDIS Notification');
            Task tsk = new Task( whatId = subs[0].Id, ownerId = (taskAssignee != null) ? taskAssignee.Id : null, priority = 'Urgent', subject = 'DD Setup Failure ' + Date.today(), Status = 'Not Started', Description = errorDesc);
            try{
                insert tsk;
            } catch(DMLException ex){
                handleSingleDMLException(ex, tsk);
            }

        } else{
            accs[0].Subscriber_Digital_Status__c = 'Inactive';
            if(accs[0].loyaltyAccess__c == true) accs[0].loyaltyAccess__c = false;
            if(accs[0].iPadAccess__c == true) accs[0].iPadAccess__c = false;
            if(accs[0].websiteAccess__c == true) accs[0].websiteAccess__c = false;
            if(accs[0].smartphoneAccess__c == true) accs[0].smartphoneAccess__c = false;

            try{
                update accs[0];
            } catch(DMLException ex){
                handleSingleDMLException(ex, accs[0]);
            }

            Task tsk = new Task( whatId = accs[0].Id, ownerId = (taskAssignee != null) ? taskAssignee.Id : null, priority = 'Urgent', subject = 'DD Setup Failure ' + Date.today(), Status = 'Not Started', Description = errorDesc );
            try{
                insert tsk;
            } catch(DMLException ex){
                handleSingleDMLException(ex, tsk);
            }

        }

    }
    /** Called when notifcation is received that a payment failed
        An MPP TranasctionHistory record needs to be created or updated
        A task needs to be created for the CSP
    */
    public static void paymentFailure(String TSNumber, SubscriptionsWebservices.Payment paymentDetails,
        String FailureReason, String FailureCode){

        // re-factored for PP-1702
        SubscriptionsWebservices.Subscriber subscriber =  new SubscriptionsWebservices.Subscriber();
        subscriber.TSNumber = TSNumber;
        paymentFailure(subscriber, paymentDetails, failureReason, failureCode);
    }

   /**
     * Called when notifcation is received that a payment failed
     * An MPP TranasctionHistory record needs to be created or updated
     * A task needs to be created for the CSP
     * Method accepts now SubscriptionsWebservices.Subscriber as argument instead of TSNumber
     */
    public static void paymentFailure(SubscriptionsWebservices.Subscriber Subscriberdetails,SubscriptionsWebservices.Payment paymentDetails,String FailureReason, String FailureCode){

        //Changes Made to Retrieve TSNumber from Subscriberdetails
        String TSNumber;
        if(Subscriberdetails !=null){
            TSNumber=Subscriberdetails.TSNumber;

        }
        System.debug('### TSNumber: ' + TSNumber);
        System.debug('### Payment Details: ' + paymentDetails);

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }
        if(paymentDetails == null){
            throw new WebserviceUtil.NullParameterException('PaymentDetails', '');
        }

        String errorDesc = 'Failure Reason: ' + failureReason + '\nFailure Code: ' + failureCode;

        List<Account> accs = [SELECT Id, MPP_Service_Id__c, Deceased__pc, RecordTypeId FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        if(accs == null || accs.size() == 0){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        if(String.isBlank(failureReason))
            failureReason = 'Cancelled';

        if(String.isBlank(failureCode))
            failureCode = 'Unknown';

        Boolean isDigital = accs[0].RecordTypeId == Constants.DigitalSubscriberRecordType();

        if(!TMGUtil.isDataValid(accs[0].MPP_Service_Id__c) && TMGUtil.isDataValid(paymentDetails.serviceId)){
            accs[0].MPP_Service_Id__c = paymentDetails.serviceId;
        }
        MPP_Transaction_History__c txn,txnUpdate;

        //Place holder for all MPPTxn records that will participate update operation after MPP callback
        List<MPP_Transaction_History__c> listtxn = new list<MPP_Transaction_History__c>();

        if(paymentDetails.orderId != null){
              List<MPP_Transaction_History__c> txns = [SELECT Id,Refunded_Amount__c,Refunded_Order__c, Subscription__c, Subscriber__r.Id, Subscriber__r.Deceased__pc,
                                                            Subscriber__r.RecordTypeId, Subscriber__r.Subscriber_Digital_Status__c
                                                     FROM MPP_Transaction_History__c
                                                     WHERE Order_id__c = :paymentDetails.orderId
                                                     AND DD_Transaction_Type__c != 'AUDDIS'];

            if(txns != null && txns.size() > 0){
                txn = txns[0];
            }
        }

        // Could find or didn't have a transaction - create one
        if(txn == null){
            txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Payment_Date__c = paymentDetails.paymentDate, Payment_Type__c = paymentDetails.paymentType,
                Total_Price__c = paymentDetails.amountGross, Expected_Amount__c = paymentDetails.amountGross, Payment_status__c = paymentDetails.paymentStatus, Failure_Code__c = failureCode,
                Failure_Reason__c = failureReason, Currency__c = paymentDetails.currencyType, Digital_Subscription_ID__c = paymentDetails.digitalSubscriptionID);
        }

        // Record the failure in the transaction history
        // only if it's not a digital cancellation
        if(!(isDigital && FailureCode == Constants.DD_CODE_CANCELLED)){
            txn.Payment_status__c = 'Failed';
            txn.Failure_Code__c = FailureCode;
            txn.Failure_Reason__c = FailureReason;
            txn.Total_Price__c = 0;
        }

        txn.Sale_Type__c='Sale';
        if(paymentDetails.orderId != null)
          txn.Order_ID__c=paymentDetails.orderId;

        if(txn.Refunded_Order__c!=null)
        {
            //AS a part of PP-1257 UAT fix
            //Compare Order_id__c with Refunded Order
            List<MPP_Transaction_History__c> Actualtxns = [SELECT Id,Refunded_Amount__c,Refunded_Order__c, Subscription__c, Subscriber__r.Id, Subscriber__r.Deceased__pc,
                                                            Subscriber__r.RecordTypeId, Subscriber__r.Subscriber_Digital_Status__c
                                                     FROM MPP_Transaction_History__c
                                                     //WHERE name = :txn.Refunded_Order__c
                                                     where order_id__c=:txn.Refunded_Order__c
                                                     ];


            if(Actualtxns != null && Actualtxns.size() > 0){
                txnUpdate = Actualtxns[0];
            }
            txnUpdate.Refunded_Amount__c-=txn.Refunded_Amount__c ;
            //For Refund Process Transaction will be Refund
            txn.Sale_Type__c='Refund';
            txn.Payment_status__c = 'Failed';
            txn.Total_Price__c = 0;
        }
        System.debug('Txn-->'+txn);
        System.debug('txnUpdate-->'+txnUpdate);
        if(txn!=null)
         listtxn.add(txn);

        if(txnUpdate!=null)
         listtxn.add(txnUpdate);

        // Create/update the transaction history
         try{
            if(listtxn.size()>0)
            upsert listtxn;
        } catch(DMLException ex){
            handleSingleDMLException(ex, txn);
        }

        Subscription__c sub;
        List<Subscription__c> subs=new List<Subscription__c>();
        boolean subWasActive = false;
        // For premium we need to work on the subscription
        if(!isDigital){

             /* check if premiumSub id is available in payment details
              * if yes, then it should participate in fetching the exact subscription along with the account id
              */
            if(Paymentdetails != null
                && paymentDetails.recurringDetails != null
                && Paymentdetails.recurringDetails.premiumSubscriptionID != null) {

                String premiumSubId = paymentDetails.recurringDetails.premiumSubscriptionID;


                                  subs = [SELECT Id, Subscription_Status__c, Cancellation_Reason__c, Cancellation_Method__c, Cancellation_Date__c, Start_Date__c
                                         FROM Subscription__c
                                         WHERE Subscriber__c = :accs[0].Id AND (Subscription_Status__c = 'Active' OR Subscription_Status__c = 'Pending Cancellation' OR Subscription_Status__c = 'Pending')
                                         AND MPP_Premium_Subscription_ID__c = :premiumSubId ];

                }
            else
               {
                                  subs = [SELECT Id, Subscription_Status__c, Cancellation_Reason__c, Cancellation_Method__c, Cancellation_Date__c, Start_Date__c
                                         FROM Subscription__c
                                         WHERE Subscriber__c = :accs[0].Id AND (Subscription_Status__c = 'Active' OR Subscription_Status__c = 'Pending Cancellation' OR Subscription_Status__c = 'Pending')];
               }
            if(subs.size() == 0)
                return;

            sub = subs[0];
            if(sub.Subscription_Status__c != 'Pending Cancellation'){
                subWasActive = true;
                sub.Subscription_Status__c = 'Pending Cancellation';

                List<Voucher_Adjustment__c> vouchers = [SELECT End_Date__c FROM Voucher_Adjustment__c WHERE Subscription__c = :sub.Id ORDER BY End_Date__c DESC];
                if(vouchers == null || vouchers.size() == 0){
                    sub.Cancellation_Date__c = sub.Start_Date__c;
                } else{
                    sub.Cancellation_Date__c = vouchers[0].End_Date__c;
                }
            }

            sub.Cancellation_Reason__c = FailureReason;
            sub.Cancellation_Method__c = 'Payment Failure';

            System.debug('### Subscription Id: ' + sub.Id);
            System.debug('### Subscription Start Date: ' + sub.Start_Date__c);
            System.debug('### Subscription Cancellation Date: ' + sub.Cancellation_Date__c);
        }

        // Get the user for the task
        List<User> users = [SELECT Id FROM User WHERE name ='System'];
        User taskAssignee;
        if(users != null && users.size() > 0)
            taskAssignee = users[0];

        // Create Tasks
        Task tsk;
        if(isDigital){
            if(FailureCode == Constants.DD_CODE_CANCELLED)
                tsk = new Task(ownerId = (taskAssignee != null) ? taskAssignee.Id : null, priority = 'Urgent', Status = 'Completed', Subject = 'User has cancelled their DD ' + date.today(), whatId = accs[0].Id, Description = errorDesc);
            else
                tsk = new Task(ownerId = (taskAssignee != null) ? taskAssignee.Id : null, priority = 'Urgent', Status = 'Not Started', Subject = (paymentDetails.paymentType == 'CreditDebitCard' ? 'Card' : 'DD') + ' Payment Failure ' + date.today(), whatId = accs[0].Id, Description = errorDesc);
        } else{
            if(FailureCode == Constants.DD_CODE_CANCELLED)
                tsk = new Task(ownerId = (taskAssignee != null) ? taskAssignee.Id : null, priority = 'Urgent', Status = (subWasActive ? 'Not Started' : 'Completed'), Subject = 'User has cancelled their DD ' + date.today(), whatId = sub.Id, Description = errorDesc);
            else
                tsk = new Task(ownerId = (taskAssignee != null) ? taskAssignee.Id : null, priority = 'Urgent', Status = 'Not Started', Subject = (paymentDetails.paymentType == 'CreditDebitCard' ? 'Card' : 'DD') + ' Payment Failure ' + date.today(), whatId = sub.Id, Description = errorDesc);

        }

        // Create the task
        if(tsk != null){
            try{
                insert tsk;
            } catch(DMLException ex){
                handleSingleDMLException(ex, tsk);
            }
        }

        // Update the subscription if needed
        if(sub != null){
            try{
                update sub;
            } catch(DMLException ex){
                handleSingleDMLException(ex, sub);
            }
        }

        Boolean updateAccount = false;

        // For digital non cancellation make it active
        // Have to set this back as the trigger will have set it to inactvie
        if(isDigital && FailureCode == Constants.DD_CODE_CANCELLED){
            accs[0].Subscriber_Digital_Status__c = 'Active';
            updateAccount = true;
        }

        // If the subscriber is deceased update the account
        if(FailureCode == Constants.DD_CODE_DECEASED){
            accs[0].Deceased__pc = true;
            updateAccount = true;
        }

        //We always update the account to trigger samBulkUpdate
        try{
            update accs[0];
        } catch(DMLException ex){
            handleSingleDMLException(ex, accs[0]);
        }
    }

    // Move a subscription to Pending Cancellation and set all the necessary fields
    private static void moveSubToPendingCancellation(Subscription__c sub, String cancellationReason, String cancellationMethod){
        sub.Subscription_Status__c = 'Pending Cancellation';

        // Need to map the possible incoming values to the picklist
        sub.Cancellation_Reason__c = cancellationReason;
        sub.Cancellation_Method__c = cancellationMethod;

        // If the subscriber has no vouchers cancellation date is sub start date
        // Otherwise it's the end of the vouchers that they have in hand
        List<Voucher_Adjustment__c> vouchers = [SELECT End_Date__c FROM Voucher_Adjustment__c WHERE Subscription__c = :sub.Id ORDER BY End_Date__c DESC];
        if(vouchers == null || vouchers.size() == 0){
            sub.Cancellation_Date__c = sub.Start_Date__c;
        } else{
            sub.Cancellation_Date__c = vouchers[0].End_Date__c;
        }

        try{
            update sub;
        } catch(DMLException e){
            handleSingleDMLException(e, sub);
        }
    }

    // Get the details needed for CPC for an active subscription
    public static SubscriptionsWebservices.ActiveSubscription getActiveSubscriptionDetails(String TSNumber){

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        List<Subscription__c> subs = [SELECT    Id,
                                                Subscription_Status__c,
                                                Subscription_Duration_Picklist__c,
                                                Next_Voucher_Batch__c,
                                                Weekly_Price__c,
                                                End_Date__c,
                                                Payment_Type__c,
                                                Total_Price__c,
                                                isContinuous__c,
                                                Subscriber__r.IsUsingMPP__c
                                            FROM Subscription__c
                                            WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber
                                            ORDER BY End_Date__C DESC];
        if(subs.isEmpty()){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        Subscription__c activeSub;
        for(Subscription__c sub : subs){
            if(sub.Subscription_Status__c == Constants.SSTATUS_ACTIVE || sub.Subscription_Status__c == Constants.SSTATUS_PENDING || sub.Subscription_Status__c == Constants.SSTATUS_IN_RENEWAL){
                activeSub = sub;
                break;
            }
        }

        if(activeSub == null){
            throw new WebserviceUtil.NoActiveSubscriptionException();
        }

        SubscriptionsWebservices.ActiveSubscription ret = new SubscriptionsWebservices.ActiveSubscription();
        ret.TSNumber = TSNumber;
        ret.ExpiryDate = activeSub.End_Date__c;
        ret.WeeklyPrice = activeSub.Weekly_Price__c;
        ret.NextVoucherPack = activeSub.Next_Voucher_Batch__c;
        ret.PaymentType = activeSub.Payment_Type__c;
        ret.IsMPP = activeSub.Subscriber__r.isUsingMPP__c;
        if(activeSub.isContinuous__c){
            ret.SubscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS.capitalize();
        } else{
            ret.SubscriptionType = activeSub.Subscription_Duration_Picklist__c;
        }

        if(activeSub.Subscriber__r.IsUsingMPP__c){
            List<MPP_Transaction_History__c> txns = [SELECT Id, Payment_Date__c, Total_Price__c FROM MPP_Transaction_History__c WHERE Subscription__c = :activeSub.Id AND DD_Transaction_Type__c != 'AUDDIS' ORDER BY Payment_Date__c DESC];
            if(!txns.isEmpty()){
                ret.LastPaymentDate = txns[0].Payment_Date__c.date();
                ret.LastPaymentAmount = txns[0].Total_Price__c;
            }
        }
        return ret;
    }


    //Get the details needed for CPC for an active subscription
    public static SubscriptionsWebservices.ActiveAndRenewedSubscriptionResult getActiveAndRenewedSubscriptionDetails(String TSNumber, String Postcode){

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        if(Postcode == null){
            throw new WebserviceUtil.NullParameterException('Postcode', '');
        }

        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c, Start_Date__c,Subscription_Duration_Picklist__c, Next_Voucher_Batch__c, Weekly_Price__c, End_Date__c, Payment_Type__c, Total_Price__c, isContinuous__c, Subscriber__r.IsUsingMPP__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber ORDER BY End_Date__C DESC];
        if(subs == null || subs.size() == 0){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        Subscription__c activeSub;
        Subscription__c renewedSub;
        for(Subscription__c sub : subs){
            if((sub.Subscription_Status__c == 'Active'  || sub.Subscription_Status__c == 'Lapsed' || sub.Subscription_Status__c == 'In Renewal') && activeSub == null){
                activeSub = sub;
            }
            //MIRFAN@Appirio, If Pending status means the payment was successful by MPP.
            if(renewedSub==null && sub.Subscription_Status__c == 'Pending')
            {
                renewedSub = sub;
            }
        }
        System.debug('#######Mirfan activeSub :'+activeSub );
        System.debug('#######Mirfan renewedSub :'+renewedSub );

        SubscriptionsWebservices.ActiveAndRenewedSubscriptionResult ret = new SubscriptionsWebservices.ActiveAndRenewedSubscriptionResult();

        System.debug('#######Mirfan before activeSub ');
        if(activeSub != null && (activeSub.Subscription_Status__c != 'Lapsed' || (activeSub.Subscription_Status__c == 'Lapsed' && renewedSub == null))){
            SubscriptionsWebservices.ActiveAndRenewedSubscription asActive = new SubscriptionsWebservices.ActiveAndRenewedSubscription();
            asActive.TSNumber = TSNumber;
            asActive.ExpiryDate = activeSub.End_Date__c;
            asActive.WeeklyPrice = activeSub.Weekly_Price__c;
            asActive.NextVoucherPack = activeSub.Next_Voucher_Batch__c;
            asActive.PaymentType = activeSub.Payment_Type__c;
            asActive.IsMPP = activeSub.Subscriber__r.isUsingMPP__c;
            asActive.Status = activeSub.Subscription_Status__c;
            if(activeSub.isContinuous__c){
                asActive.SubscriptionType = 'Continuous';
            } else{
                asActive.SubscriptionType = activeSub.Subscription_Duration_Picklist__c;
            }

            if(activeSub.Subscriber__r.IsUsingMPP__c){
                List<MPP_Transaction_History__c> txns = [SELECT Id, Payment_Date__c, Total_Price__c FROM MPP_Transaction_History__c WHERE Subscription__c = :activeSub.Id AND DD_Transaction_Type__c != 'AUDDIS' ORDER BY Payment_Date__c DESC];
                if(txns != null && txns.size() != 0){
                    asActive.LastPaymentDate = txns[0].Payment_Date__c.date();
                    asActive.LastPaymentAmount = txns[0].Total_Price__c;
                }
            }

            ret.Subscriptions.add(asActive);
        }
        System.debug('#######Mirfan before renewedSub ');
        if(renewedSub != null){
            SubscriptionsWebservices.ActiveAndRenewedSubscription asRenewed  = new SubscriptionsWebservices.ActiveAndRenewedSubscription();
            asRenewed.TSNumber = TSNumber;
            asRenewed.ExpiryDate = renewedSub.End_Date__c;
            asRenewed.StartDate = renewedSub.Start_Date__c;
            asRenewed.WeeklyPrice = renewedSub.Weekly_Price__c;
            asRenewed.NextVoucherPack = renewedSub.Next_Voucher_Batch__c;
            asRenewed.PaymentType = renewedSub.Payment_Type__c;
            asRenewed.IsMPP = renewedSub.Subscriber__r.isUsingMPP__c;
            asRenewed.Status = renewedSub.Subscription_Status__c;
            if(renewedSub.isContinuous__c){
                asRenewed.SubscriptionType = 'Continuous';
            } else{
                asRenewed.SubscriptionType = renewedSub.Subscription_Duration_Picklist__c;
            }
            ret.Subscriptions.add(asRenewed);

        }
        System.debug('#######Mirfan ret:'+ret);
        return ret;
    }

    /** Get the details needed for CPC for a lapsed subscription
    */
    public static SubscriptionsWebservices.LapsedSubscription getLapsedSubscriptionDetails(String TSNumber){

        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        /////////////////////////////////////////Change Log///////////////////////////////////////////////////////////////////////////
        //// 1=> Remove Withdrawn and Declined from the list of status
        //// 2=> Add condition in query to evaluate only those susbcriptions for which current week position (formula field) is > 0
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        String statuses = 'Lapsed;Cancelled;Temporary Suspension;Pending Cancellation';
        List<Subscription__c> subs = [SELECT Id,Current_Week_Position__c,End_Date__c, Cancellation_Date__c, Subscription_Status__c, Subscription_Duration_Picklist__c, isContinuous__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber AND Subscription_Status__c IN :statuses.split(';') AND Current_Week_Position__c > 0 ORDER BY Start_Date__c DESC];

        if(subs == null || subs.size() == 0){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        SubscriptionsWebservices.LapsedSubscription ret = new SubscriptionsWebservices.LapsedSubscription();
        ret.TSNumber = TSNumber;

        // Only look at setting renewable if the subscription is recently lapsed
        if(subs[0].Subscription_Status__c == 'Lapsed' && Date.today() < subs[0].End_Date__c.addDays(13*7)){
            List<Subscription__c> offeredSubs = [SELECT Id FROM Subscription__c WHERE Previous_Subscription__c = :subs[0].Id AND Subscription_Status__c = 'Offered'];
            ret.IsRenewable = (offeredSubs != null && offeredSubs.size() > 0);
        } else{
            ret.IsRenewable = false;
        }

        if(subs[0].isContinuous__c){
            ret.SubscriptionType = 'Continuous';
        } else{
            ret.SubscriptionType = subs[0].Subscription_Duration_Picklist__c;
        }

        ret.Expired = (subs[0].Cancellation_Date__c != null) ? subs[0].Cancellation_Date__c : subs[0].End_Date__c;
        return ret;
    }


      /**
     * Re-factored as part of PP-1695
     */
     public static void clearDigitalEntitlements(List<String> samGUIDs, String newEntitlement) {

        //Make sure we don't get duplicates.
        Set<String> samIds = new Set<String>(samGUIDS);
        Set<String> accountGUIDs = new Set<String>();
        Set<Id> accIds = new Set<Id>();
        List<Account> updateAccList = new List<Account>();
        system.debug('SAMGUIds : '+samIds);
        //Do internal SFDC sqol batching here to handle large data sets to update.
        for(List<Account> accList :[SELECT Id, Number_of_Active_Subscriptions__c, Number_of_In_Renewal_Subscription__c,
        Number_of_Pending_Subscriptions__c, RecordTypeId, MPP_Service_Id__c, MPP_Digital_Payment_Id__c, Subscriber_Digital_Status__c,Guid__c  FROM Account WHERE Guid__c IN :samIds]){
            for(Account acc :accList){

               system.debug('Number_of_Active_Subscriptions__c = '+acc.Number_of_Active_Subscriptions__c);
               system.debug('Number_of_In_Renewal_Subscription__c = '+acc.Number_of_In_Renewal_Subscription__c);
               system.debug('Number_of_Pending_Subscriptions__c = '+acc.Number_of_Pending_Subscriptions__c);
               system.debug('acc.RecordTypeId = '+acc.RecordTypeId);
               system.debug('acc.MPP_Digital_Payment_Id__c = '+acc.MPP_Digital_Payment_Id__c);
               system.debug('Account.Individual Subscriber recordTypeId = '+TMGUtil.recordTypeMap.get('Account.Individual Subscriber').Id);
               system.debug('Digital Subscriber recordTypeId = '+TMGUtil.recordTypeMap.get('Account.Digital Subscriber').Id);
               // check if the subscriber is Digital
               if(acc.RecordTypeId == TMGUtil.recordTypeMap.get('Account.Digital Subscriber').Id) {
                     // check if the MPP_Payment_ID__c (new field) is null,
                     // if null, then it means this came from app store via TigerSpike
                     // set the status to inactive and add to the update list
                     if(acc.MPP_Digital_Payment_Id__c == null && acc.MPP_Service_Id__c == null) {
                        // add to the list for update
                        system.debug(acc.Guid__c+' does not have an MPP id so  MARKING as inactive');
                           acc.Subscriber_Digital_Status__c = 'Inactive';
                           updateAccList.add(acc);
                     }
                     else
                     {
                          system.debug(acc.Guid__c+' does have an MPP id so  NOT MARKING as inactive');
                         samIds.remove(acc.Guid__c);
                     }
               } else if(acc.RecordTypeId == TMGUtil.recordTypeMap.get('Account.Individual Subscriber').Id) { // subscriber is premium
                     // if exists subscriptions, do nothing
                     if((acc.Number_of_Active_Subscriptions__c
                            + acc.Number_of_In_Renewal_Subscription__c
                            + acc.Number_of_Pending_Subscriptions__c) > 0) {
                                  system.debug(acc.Guid__c+' has an active, In Renewal or Pending Sub, so NOT MARKING as inactive');
                           samIds.remove(acc.Guid__c);

                     } else { // add to the list for update
                        system.debug(acc.Guid__c+' has no active, In Renewal or Pending Sub, so MARKING as inactive');
                         acc.Subscriber_Digital_Status__c = 'Inactive';
                         updateAccList.add(acc);
                     }
               }
            }

            //Disable callout to SAM in trigger as we will do this last.
            SubscriberPortal.SUB_TRIGGER_FIRED = true;
            Constants.MPP_CALLOUT_DISABLED = true;

            update updateAccList;
            //Calling SAM to cancel entitlements for GUIDs which do not have a Salesforce Account
          //  samIds.removeAll(accountGUIDs);

        }

        //Call SAM async.
        if(samIds.size() > 0) {
            callSamUpdate(samIds,accIds,newEntitlement);
        }
    }

    @future(callout=true)
    private static void callSamUpdate(Set<String> gUIDs,Set<Id> accIds,String entitlement){
        //Call SAM here and disable in trigger.
        UpdateSamUserDetailsBatch.callSamToUpdateEntitlement(gUIDs,entitlement,accIds, UpdateSamUserDetailsBatch.UPDATE_EMAIL);
    }


    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
	Function - Called when a soft cancel reaches the end date in MPP
    #############Change Log#############
    Modified by    		Version     Change Date
    ****************************************************************************************/
    public static void digitalSubscriptionEnded(String TSNumber){
        if(TSNumber == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        if(accs == null || accs.size() == 0){
            throw new WebserviceUtil.UnknownTSNumberException('3',TSNumber);
        }

        accs[0].Subscriber_Digital_Status__c = 'Inactive';

        // added as part of PP-1695
        accs[0].MPP_Digital_Payment_Id__c = null;

        try{
            update accs[0];
        } catch(DMLException ex){
            handleSingleDMLException(ex, accs[0]);
        }

    }

    /** Get the a zero based day of the week
        0 = Monday, etc.
    */
    private static integer getWeekday(Date input){
        return input.toStartOfWeek().daysBetween( input );
    }

    /** Has this GUID been assigned to an Account already?
    */
    private static boolean isGUIDAvailable(String GUID){
        return ([Select id From Account Where Guid__c = : GUID].size() == 0);
    }

    /************************************************************************************
    Developer - Unknown
    Date - Unknown
    Function - Return the details of an account for a given TSNumber
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         29/03/2016  //added Product__c, Product__r.Name to query string
    *************************************************************************************/
    public static Account getAccountByTSNumber(String TSNumber){
        System.debug('getAccountByTsNumber getting account details for  : '+TSNumber);
        Account a;
        List<Account> accounts = [SELECT id,PricingOptionID__c,Partner_Token__c,Token_Source__c, GUID__c, Salutation, FirstName, LastName, PersonEmail, PersonMailingStreet,
                                         PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, MPP_Service_Id__c,
                                         PersonHomePhone, Origin__c, Email_Sent__c, TMG_Promo_Email__c, TMG_Promo_Phone__c,
                                         TMG_Promo_Post__c, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Loyalty_SMS__c,
                                         Subscriber_Number_static__c, Subscriber_Digital_Status__c, RecordTypeId, isUsingMPP__c,
                                         Website_First_Accessed__c, Website_Last_Accessed__c, Tablet_First_Accessed__c,
                                         Tablet_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c,
                                         Digital_Product_Type__c, loyaltyAccess__c, websiteAccess__c, smartphoneAccess__c,
                                         iPadAccess__c, Subscription_Status__c, Number_of_Subscriptions__c ,
                                         Promo_Code__c ,Promotion_Name__c , Promo_Code_Expiry_Date__c,Email_Retry__c,Email_to_be_Send__c,
                                         MPP_CurrentPayScheduleEndDate__c, Credit_Card_Expiry_Date__c,Product__c,Product__r.Name
                                  FROM   Account
                                  WHERE  Subscriber_Number_static__c = : TSNumber];

        if( accounts != null && accounts.size() > 0 ){
            System.debug('getAccountByTsNumber returning : '+accounts[0]);
            return accounts[0];
        } else{
            return null;
        }
    }

    /**
    * For a given Account object set the fields passed in.
    * @param a                     the account object
    * @param subscriberDetails     the subscriber details
    * @param paymentDetails        the payment details associated with the subscriber
    * @param subscriptionDetails   the subscription details
    * @return the TSNumber generated for the subscriber
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         06/08/2015  //cleaned-up a bit, changed record type fetching methods, moved Order_Taken... fields
    Wiktor Czykin   1.2         22/09/2015  //added if to prevent Wave_Id__c blanking out on Account
    Wiktor Czykin   1.3         25/02/2016  //made sure the record type is not changed from Registrant back to old Digital
    Wiktor Czykin   1.4         03/01/2017 //modified so that null subscriberType value does not have impact on the record type 
    */
    @TestVisible private static Account setAccountFields(   Account a,
                                                            SubscriptionsWebservices.Subscriber subscriberDetails,
                                                            SubscriptionsWebservices.Payment paymentDetails,
                                                            SubscriptionsWebservices.Subscription subscriptionDetails,
                                                            SubscriptionsWebservices.MPPRecurringInfo recurringDetails){
        System.debug('TMGLOG::SubscriptionWebservicesHandlers:setAccountFields:recurringDetails:'+recurringDetails);
        if(subscriberDetails.GUID != null){
            a.Guid__c = subscriberDetails.GUID;
        }

        if(subscriberDetails.productId != null){
            a.Product__c = subscriberDetails.productId;
        }

        String currentRecordType = RecordTypeUtility.getRecordTypeName(Account.sObjectType, a.RecordTypeId, Account.class.getName());
        String newRecordType = subscriberTypes.get(subscriberDetails.subscriberType.toLowerCase().trim());

        if (currentRecordType != newRecordType){
            if(currentRecordType == Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME && newRecordType == Constants.RECTYPE_DIGISUB){
                newRecordType = Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME;
            }
        }

        if(!subscriberDetails.isPrint){
            String prevDigitalStatus = a.Subscriber_Digital_Status__c;
            if(prevDigitalStatus == Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE && subscriberDetails.digitalSubscriberStatus == Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE){
                a.Cancellation_Type__c = null;
                a.Cancelled_By__c = null;
                a.Cancelled_Date__c = null;
            }
            a.Subscriber_Digital_Status__c = subscriberDetails.digitalSubscriberStatus;

            //Changes Made to Retrieve TSNumber from Subscriberdetails
            String TSNumber;
            if(Subscriberdetails != null){
                TSNumber=Subscriberdetails.TSNumber;
            }
            //Retrieve Account detail based on TSNumber
            Account AccountDetails=getAccountByTSNumber(TSNumber)  ;
            /**
            *For digital subscribers, set the previous promo fields
            ** After the Promo expiry make promo code, promotion name and promo expiry date as null
            ** Populate previous promo code, previous promotion name and previous promo expiry date.
            */
            if(AccountDetails!=null && Date.today() > AccountDetails.Promo_Code_Expiry_Date__c){
                a.previous_Promo_Code__c = AccountDetails.Promo_Code__c;
                a.previous_Promotion_Name__c = AccountDetails.Promotion_Name__c;
                a.previous_Promo_Code_Expiry_Date__c = AccountDetails.Promo_Code_Expiry_Date__c;

                a.Promo_Code__c = null;
                a.Promotion_Name__c =null;
                a.Promo_Code_Expiry_Date__c = null;
            }

            //for digital subscribers, set the promo fields
            if(subscriptionDetails != null) {
                a.Promo_Code__c = subscriptionDetails.promoCode;
                a.Promotion_Name__c = subscriptionDetails.promoName;
                a.Promo_Code_Expiry_Date__c = subscriptionDetails.promoValidToDate;
            }
        }

        // DM 01/05/2013 - if a PricingOptionID is being passed, then get the Wave_ID__c using this relationship.
        if (subscriberDetails.PricingOptionID != null){
            Pricing_Options__c pricingOption = getPricingOptionByName(subscriberDetails.PricingOptionID);
            if(pricingOption != null){
                a.Pricing_Option__c = pricingOption.ID;
            }
        }

        a.Wave_ID__c = (String.isNotBlank(subscriberDetails.TCode) ? subscriberDetails.TCode : null);
        String prevRecordTypeID = a.RecordTypeID;
        if(String.isNotBlank(newRecordType)){
            a.RecordTypeID = RecordTypeUtility.getRecordTypeId(Account.SObjectType, newRecordType, Account.class.getName());
        }
        a.Salutation = subscriberDetails.title;
        a.FirstName = subscriberDetails.firstName;
        a.LastName = subscriberDetails.lastName;
        a.PersonEmail= subscriberDetails.personalEmail;
        if(subscriberDetails.street != null ){
            String street = SubscriberPortal.BuildAddressLine1(subscriberDetails.street);
            a.PersonMailingStreet = street.replaceAll('\\|', '\n').trim();
        }
        a.PersonMailingCity = subscriberDetails.city;
        a.PersonMailingState = subscriberDetails.county;
        if(subscriberDetails.country == Constants.COUNTRY_CODE_GB)
            a.PersonMailingPostalCode = subscriberPortal.FormatPostCode(subscriberDetails.postalCode);
        else
            a.PersonMailingPostalCode = subscriberDetails.postalCode;

        a.PersonMailingCountry = subscriberDetails.country;
        a.PersonHomePhone = subscriberDetails.homePhone;
        a.PersonMobilePhone = subscriberDetails.mobilePhone;
        a.Origin__c = 'Online';

        if(a.Id == null){
            a.Email_Sent__c = false;
            // Only set isUsingMPP if it's a new account
            a.isUsingMPP__c = true;
        }

        //If someone is linking to another subscription then don't send welcome email.
        if(a.Id != null && a.RecordTypeID == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())
            && a.Number_of_Subscriptions__c > 1 && !a.Email_Sent__c){
            a.Email_Sent__c = true;
        }

        //If someone is upgrading or downgrading then send welcome email?
        if(a.Id != null && prevRecordTypeID != null && prevRecordTypeID != a.RecordTypeID){
            a.Email_Sent__c = false;
        }

        a.TMG_Promo_Email__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingEmailPref);
        a.TMG_Promo_Phone__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingPhonePref);
        a.TMG_Promo_Post__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingPostPref);
        a.TMG_Promo_SMS__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingSMSPref);
        a.TMG_Loyalty_Email__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingEmailPref);
        a.TMG_Loyalty_Phone__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingPhonePref);
        a.TMG_Loyalty_Mail__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingPostPref);
        a.TMG_Loyalty_SMS__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingSMSPref);

        if(a.Website_First_Accessed__c == null){
            a.Website_First_Accessed__c = a.Website_Last_Accessed__c = datetime.now();
        }

        // Set the flags and types for entitlements
        a = setAccountProductTypeAndAccessFlags(a, subscriberDetails);

        if(paymentDetails != null){
            a.MPP_Digital_Payment_Id__c = paymentDetails.digitalSubscriptionID;

            //Set order taken fields only when new subscription is purchased
            a.Order_Taken_Date__c = Date.today();
            a.Order_Taken_By_Company__c = Label.Webservices_TMG;
            a.Order_Taken_By_User_Department__c = Label.Webservices_Online_user_department;
            a.Order_Taken_Method__c = Label.Webservices_Order_taken_method_online;
        }

        if(subscriberDetails.token!=null){
            if(subscriberDetails.token.tokenValue!=null)
                a.Partner_Token__c=subscriberDetails.token.tokenValue;
            if(subscriberDetails.token.tokenSource!=null)
                a.Token_Source__c=subscriberDetails.token.tokenSource;
        }

        if(subscriberDetails.PricingOptionID!=null){
            a.PricingOptionID__c=subscriberDetails.PricingOptionID;
        }
        //Put DigitalSubscriberStatus into a consistent format
        if(subscriberDetails.digitalSubscriberStatus != null){
            subscriberDetails.digitalSubscriberStatus = correctFormatOfDigitalSubscriberStatus(subscriberDetails.digitalSubscriberStatus);
        }

        System.debug('TMGLOG::SubscriptionWebservicesHandlers:setAccountFields:subscriptionDetail:'+subscriptionDetails);
        if(subscriptionDetails!=null && subscriptionDetails.subscriptionType!=null){
            a.Subscription_Frequency__c = subscriptionDetails.subscriptionType;
        }
        return a;
    }


    /** Get the correct digital product type depending on the subscription type
    */
    private static Account setAccountProductTypeAndAccessFlags(Account acc, SubscriptionsWebservices.Subscriber subscriberDetails){
        //Reset the entitlement flags first, we need this in case product types change.
        acc.iPadAccess__c = false;
        acc.smartphoneAccess__c = false;
        acc.websiteAccess__c = false;
        acc.loyaltyAccess__c = false;
        acc.Digital_Product_Type__c = null;

        // Webpack
        if(subscriberDetails.subscriberType == 'webpack'){
            acc.smartphoneAccess__c = true;
            acc.websiteAccess__c = true;
            acc.Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_WEBPACK;
            if(acc.Id == null){
                acc.Mobile_Free_Trial_Used__c = true;
            }
            return acc;
        }

        // All devices
        if(subscriberDetails.subscriberType == 'digital'){
            acc.iPadAccess__c = true;
            acc.smartphoneAccess__c = true;
            acc.websiteAccess__c = true;
            acc.loyaltyAccess__c = (subscriberDetails.country == Constants.COUNTRY_CODE_GB);
            acc.Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_ALLDEVICES;
            if(acc.Id == null){
                acc.Digital_Low_Start_Used__c = true;
            }
            return acc;
        }

        if(subscriberDetails.subscriberType == 'premium'){
            acc.iPadAccess__c = true;
            acc.smartphoneAccess__c = true;
            acc.websiteAccess__c = true;
            acc.loyaltyAccess__c = (subscriberDetails.country == Constants.COUNTRY_CODE_GB);
            return acc;
        }

        return acc;
    }


    private static MPP_Transaction_History__c setTransactionFields(MPP_Transaction_History__c t, String accountID, boolean isPremium, SubscriptionsWebservices.Payment paymentDetails, SubscriptionsWebservices.DirectDebitInfo directDebitDetails, Boolean updateSubOnMapping){
        return setTransactionFields(t,accountID,isPremium,paymentDetails,directDebitDetails,updateSubOnMapping,null);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  For a given transaction record set the fields to the data passed in
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         26/10/2015  //set DD account name to 255chars in case is longer than that
    Michal Szewczyk     1.2         18/10/2016  //Added One_Time_Payment_Reason__c population from  clientCustomParams
    ****************************************************************************************/
    private static MPP_Transaction_History__c setTransactionFields(MPP_Transaction_History__c t, String accountID, boolean isPremium, SubscriptionsWebservices.Payment paymentDetails, SubscriptionsWebservices.DirectDebitInfo directDebitDetails, Boolean updateSubOnMapping,SubscriptionsWebservices.CustomParameter[] clientCustomParams){

        Subscription__c curSub = null;
        String clientParamSubId = null;
        String clientParamOneOffPaymentReason = null;

        if (clientCustomParams != null){
            for(SubscriptionsWebservices.CustomParameter clientCustomParam : clientCustomParams){
                System.debug('Param Name: '+clientCustomParam.name+'Param Value'+clientCustomParam.value);
                if (clientCustomParam.name == 'SubscriptionId'){
                    clientParamSubId = clientCustomParam.value;
                }
                if (clientCustomParam.name == 'PaymentReason'){
                    clientParamOneOffPaymentReason = clientCustomParam.value;
                }
            }
        }

        // Get hold of the subscription that this transaction relates to
        if(isPremium && clientParamSubId == null){

            String query = 'SELECT Id, MPP_Premium_Subscription_ID__c, MPP_CC_First_Payment_Amount__c,'
                           + 'MPP_CC_Frequency__c, MPP_CC_Next_Payment_Date__c, MPP_DD_First_Payment_Amount__c,'
                           + 'MPP_DD_Frequency__c, MPP_DD_Next_Payment_Date__c, isContinuous__c, Start_Date__c,'
                           + 'End_Date__c, Subscription_Status__c, Digital_VAT_Rate__c, Payment_Type__c,Is_One_Off_Payment__c'
                           + ' FROM Subscription__c WHERE Subscriber__c = :accountID';
            String orderQuery = ' ORDER BY Start_Date__c DESC';

            /* for Online flows, check if premiumSub id is available in payment details
             * if yes, then it should participate in fetching the exact subscription along with the account id
             */
            if(paymentDetails != null
                && paymentDetails.recurringDetails != null
                && paymentDetails.recurringDetails.premiumSubscriptionId != null) {
                String premiumSubId = paymentDetails.recurringDetails.premiumSubscriptionId;

                // in this case, there should be only 1 record returned if the combination matches
                String premiumQuery = query + ' and MPP_Premium_Subscription_ID__c = :premiumSubId' + orderQuery + ' LIMIT 1';
                System.debug('QUERY STRING in setTransactionFields() for premium sub id : ' + premiumQuery);

                // assign to the curSub object
                // but check if the query returned the expected result or not
                Subscription__c [] tempSub = Database.query(premiumQuery);
                if(tempSub.size() > 0) {
                    curSub = tempSub[0];
                }
            }

            // if the curSub is not found above, then execute normally to find it for all other cases
            if(curSub == null) {
                query += orderQuery;
                System.debug('QUERY STRING in setTransactionFields() : ' + query);

                List<Subscription__c> subs = Database.query(query);

                // Look for a continuous sub that's active or pending canx
                // For continuous transactions can only be for subs that have started
                for(Subscription__c sub : subs) {
                    if(sub.isContinuous__c &&
                        (sub.Subscription_Status__c == 'Active' || sub.Subscription_Status__c == 'Pending Cancellation')) {
                        curSub = sub;
                        break;
                    }
                }

                // There's no current continuous sub
                // Instead look for the next sub to start that's offered or pending
                for(Subscription__c sub : subs) {
                    Date earliest = Date.newInstance(2100, 01, 01);
                    if(sub.Start_Date__c > date.today()
                        && sub.Start_Date__c < earliest && (sub.Subscription_Status__c == 'Active' || sub.Subscription_Status__c == 'Offered' || sub.Subscription_Status__c == 'Pending')) {
                        earliest = sub.Start_Date__c;
                        curSub = sub;
                    }
                }
            }

            if(curSub == null){
                throw new WebserviceUtil.NoActiveSubscriptionException();
            }

        }else if (clientParamSubId != null){
            curSub =  [SELECT Id, MPP_Premium_Subscription_ID__c, MPP_CC_First_Payment_Amount__c, MPP_CC_Frequency__c,
                                            MPP_CC_Next_Payment_Date__c, MPP_DD_First_Payment_Amount__c, MPP_DD_Frequency__c,
                                            MPP_DD_Next_Payment_Date__c, isContinuous__c, Start_Date__c, End_Date__c,
                                            Subscription_Status__c, Digital_VAT_Rate__c, Payment_Type__c,Is_One_Off_Payment__c
                                            FROM Subscription__c
                                            WHERE Id = :clientParamSubId
                                            LIMIT 1];
        }

        t.Subscriber__c = accountID;
        t.Subscription__c = (curSub != null) ? curSub.Id : null;
        t.VAT_Rate__c = (curSub != null) ? curSub.Digital_VAT_Rate__c : null;
        t.Total_Price__c = paymentDetails.amountGross;
        t.Expected_Amount__c = paymentDetails.amountGross;
        t.Payment_Date__c = paymentDetails.paymentDate;
        t.Currency__c = paymentDetails.currencyType;
        t.One_Time_Payment_Reason__c = clientParamOneOffPaymentReason;
        if(TMGUtil.isDataValid(paymentDetails.digitalSubscriptionID)){
            t.Digital_Subscription_ID__c = paymentDetails.digitalSubscriptionID;
        }

        if(TMGUtil.isDataValid(paymentDetails)){
            SubscriptionsWebservices.MPPRecurringInfo recurringDetails = paymentDetails.recurringDetails;
            if(TMGUtil.isDataValid(recurringDetails) && TMGUtil.isDataValid(recurringDetails.premiumSubscriptionId)){
                t.Premium_Subscription_ID__c = recurringDetails.premiumSubscriptionId;
            }
        }

        t.Payment_Status__c = (paymentDetails.paymentStatus == 'Refund') ? 'Success' : paymentDetails.paymentStatus;
        t.Payment_Type__c = paymentDetails.paymentType;
        t.Order_Id__c = paymentDetails.orderId;
        t.Card_Type__c = paymentDetails.cardType;
        t.Subscription_Type__c = (curSub != null && !curSub.isContinuous__c) ? 'One-Off' : 'Continuous';
        t.Sale_Type__c = (paymentDetails.paymentStatus == 'Refund') ? 'Refund' : 'Sale';

        if(paymentDetails.paymentType == Constants.MPP_PAYMENTMETHOD_DD){
            Integer countDDPayments = 0;
            try{
                countDDPayments = [SELECT COUNT() FROM MPP_Transaction_History__c WHERE Payment_Type__c = :Constants.MPP_PAYMENTMETHOD_DD
                    AND DD_Transaction_Type__c = 'Payment' AND Payment_Status__c = 'Success'
                    AND Subscriber__c = :accountID LIMIT 1];
            }catch(System.Exception e){
                countDDPayments = 0;
                System.debug('### No DD Payment Records Found.');
            }

            System.debug('### DD Payment Count: ' + countDDPayments);
            if(TMGUtil.isDataValid(directDebitDetails)){
                t.DD_Account_Name__c =  (directDebitDetails.accountName !=null ? directDebitDetails.accountName.LEFT(100) : directDebitDetails.accountName);
                t.DD_Account_Number__c = directDebitDetails.accountNumber;
                t.DD_Sort_Code__c = directDebitDetails.sortCode;
                t.DD_Transaction_Type__c = 'Payment';
                t.AUDDIS_Ref__c=directDebitDetails.auddisRef;
            }
            System.debug('### Payment Status: ' + t.Payment_Status__c );
        }

        Boolean isOneOffPayment = (paymentDetails != null && paymentDetails.productName != null && TMGUTil.isDataValid(paymentDetails.productName) && paymentDetails.productName.toLowerCase().equals('oneoffpayment'));
        System.debug('### Is one off Payment: ' + isOneOffPayment );

        //Have we got a valid subscription - this should be for premium subscriptions.
        if(updateSubOnMapping && isPremium && TMGUtil.isDataValid(curSub)){
            //Assign the MPP premium subscription id to the transaction history object.
            if(TMGUtil.isDataValid(paymentDetails) && TMGUtil.isDataValid(paymentDetails.recurringDetails) && !isOneOffPayment){
                update setMPPSubscriptionFields(curSub, paymentDetails.recurringDetails);
            }else if(TMGUtil.isDataValid(paymentDetails) && TMGUtil.isDataValid(paymentDetails.recurringDetails) && isOneOffPayment){
                System.debug('### Invkoking sub updated with one off payment: ');
                update setMPPSubscriptionFields(curSub, paymentDetails.recurringDetails,isOneOffPayment);
            }
        }
        return t;
    }

    public static Subscription__c setMPPSubscriptionFields(Subscription__c sub, SubscriptionsWebservices.MPPRecurringInfo recurringDetails){
        return setMPPSubscriptionFields(sub,recurringDetails,null);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.5
    Function - populates Subscription__c fields based on MPPRecuringInfor wrapper data
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/07/2015  //changed the way the MPP_DD_Next_Payment_Date__c field is set
    Cristina Anghenie1.2        18/08/2015  //populate MPP_Pay_Schedule_Start_Date__c, MPP_Pay_Schedule_End_Date__c
    Wiktor Czykin   1.3         16/09/2015  //removed frequency override on irregular
    Wiktor Czykin   1.4         05/10/2015  //added setting of MPP_Subsequent_Amount__c and MPP_Subsequent_Payment_Date__c fields
    Wiktor Czykin   1.5         21/10/2015  //modified how MPP_Subsequent_Payment_Date__c is set
    ****************************************************************************************/
    public static Subscription__c setMPPSubscriptionFields(Subscription__c sub, SubscriptionsWebservices.MPPRecurringInfo recurringDetails,Boolean isOneOffPayment){
        if(TMGUtil.isDataValid(recurringDetails)){
            if(TMGUtil.isDataValid(recurringDetails.premiumSubscriptionId)){
                sub.MPP_Premium_Subscription_ID__c = recurringDetails.premiumSubscriptionId;
            }

            System.debug('### SUB Payment Type: ' + sub.Payment_Type__c);
            System.debug('### Is Payment Type Valid: ' + TMGUtil.isDataValid(sub.Payment_Type__c));

            if(TMGUtil.isDataValid(recurringDetails.paymentType)){
                String paymentType = recurringDetails.paymentType.toLowerCase();
                if(paymentType.equals('creditdebitcard') || paymentType.equals('credit card')){
                    if(TMGUtil.isDataValid(recurringDetails.firstPaymentAmount))sub.MPP_CC_First_Payment_Amount__c = recurringDetails.firstPaymentAmount;
                    if(TMGUtil.isDataValid(recurringDetails.frequency) && recurringDetails.frequency != Constants.DD_COL_FREQ_IRREGULAR) sub.MPP_CC_Frequency__c = recurringDetails.frequency;

                    if(TMGUtil.isDataValid(recurringDetails.nextPaymentDate)){
                        sub.MPP_CC_Next_Payment_Date__c = recurringDetails.nextPaymentDate;
                        sub.MPP_Pay_Schedule_Start_Date__c = TMGDateExtension.getPaymentCollectionDate(recurringDetails.nextPaymentDate);
                        sub.MPP_Pay_Schedule_End_Date__c = TMGDateExtension.getPaymentCollectionDate(Date.valueOf(sub.MPP_Pay_Schedule_Start_Date__c.addDays(Integer.ValueOf(sub.Subscription_Duration_Picklist__c) * 7)));
                    }
                }else if(paymentType.equals('directdebit') || paymentType.equals('direct debit')){
                    if(TMGUtil.isDataValid(recurringDetails.firstPaymentAmount))sub.MPP_DD_First_Payment_Amount__c = recurringDetails.firstPaymentAmount;
                    if(TMGUtil.isDataValid(recurringDetails.frequency) && recurringDetails.frequency != Constants.DD_COL_FREQ_IRREGULAR)sub.MPP_DD_Frequency__c = recurringDetails.frequency;
                    if(TMGUtil.isDataValid(recurringDetails.nextPaymentDate)){
                        sub.MPP_DD_Next_Payment_Date__c = TMGDateExtension.getPaymentCollectionDate(recurringDetails.nextPaymentDate);
                        sub.MPP_Pay_Schedule_Start_Date__c = TMGDateExtension.getPaymentCollectionDate(recurringDetails.nextPaymentDate);
                        sub.MPP_Pay_Schedule_End_Date__c = TMGDateExtension.getPaymentCollectionDate(Date.valueOf(sub.MPP_Pay_Schedule_Start_Date__c.addDays(Integer.ValueOf(sub.Subscription_Duration_Picklist__c) * 7)));
                    }
                }
                try{
                    String sJson = (String)sub.get(Constants.MPP_IRREGULAR_PAYMENT_SCHEDULE_FIELD);
                    if(String.isNotBlank(sJson)){
                        MppUtil.PaymentSetupWrapper psw = (MppUtil.PaymentSetupWrapper) JSON.deserialize(sJson, MppUtil.PaymentSetupWrapper.class);
                        if(psw != null && psw.dSwitchAmount != null && psw.dtSwitchPaymentDate != null){
                            sub.MPP_Subsequent_Payment_Date__c = TMGDateExtension.getPaymentCollectionDate(psw.dtSwitchPaymentDate);
                            sub.MPP_Subsequent_Amount__c = psw.dSwitchAmount;
                        }
                    }
                }catch(Exception e){
                    System.debug('Fail silently on low start subsequent fields payment.');
                }
            }
        }

        System.debug('one of payment status is:'+isOneOffPayment);
        sub.Is_One_Off_Payment__c = false;
        if(isOneOffPayment != null){
            sub.Is_One_Off_Payment__c = isOneOffPayment;
        }
        return sub;
    }

    //Methods to validate input. They are here as it allows us to change how each parameter is validated quickly
    private static boolean isValidProductType(String value){
        return value != null; // && productTypes.contains(value.toLowerCase());
    }

    private static boolean isValidFlowType(String value){
        return value != null && flowTypes.contains(value.toLowerCase());
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - validates the contents of a SubscriptionsWebservices.Subscriber class
    BE AWARE: The method will throw exceptions if invalid data is found.
    #############Change Log#############
    Modified by          Version     Change Date
    Mantas Grigaliunas   1.1         09/06/2016  //removed 'iPad' subscriberType from IF condition
    Wiktor Czykin        1.2         03/02/2017  //ifed out subscriberType failures is subscriberType value is not there
    ****************************************************************************************/
    private static void validateSubscriber(SubscriptionsWebservices.Subscriber subscriber, boolean checkTCode){

        if(subscriber.subscriberType == null){
            throw new WebserviceUtil.NullParameterException('subscriber.subscriberType', '');
        }
        if(subscriber.productId == null){
            //throw new WebserviceUtil.NullParameterException('subscriber.productId', '');
        }
        if(String.isNotBlank(subscriber.subscriberType)){

            if(!subscriberTypes.keySet().contains(subscriber.subscriberType.toLowerCase())){
                throw new WebserviceUtil.InvalidFieldException('subscriber.subscriberType', subscriber.subscriberType, subscriberTypes.keySet() + '');
            }

            if(subscriber.subscriberType.toLowerCase() != 'premium' && subscriber.digitalSubscriberStatus == null){
                throw new WebserviceUtil.NullParameterException('subscriber.digitalSubscriberStatus', '');
            }
            if(subscriber.subscriberType.toLowerCase() != 'premium' && !digitalSubscriberStatuses.contains(subscriber.digitalSubscriberStatus.toLowerCase())){
                throw new WebserviceUtil.InvalidFieldException('subscriber.digitalSubscriberStatus', subscriber.digitalSubscriberStatus, digitalSubscriberStatuses + '');
            }
        }

        if(subscriber.lastName == null){
            throw new WebserviceUtil.NullParameterException('subscriber.lastName', '');
        }

        if(subscriber.country == null){
            throw new WebserviceUtil.NullParameterException('subscriber.country', '');
        }
        if(Country_Codes__c.getInstance(subscriber.country) == null){
            throw new WebserviceUtil.InvalidFieldException('subscriber.country', subscriber.country, 'A valid ISO country code');
        }


        if(checkTCode && !subscriber.subscriberType.equalsIgnoreCase('Webpack') && subscriber.TCode == null){
            throw new WebserviceUtil.NullParameterException('subscriber.TCode', '');
        }

        if(subscriber.personalEmail == null || subscriber.personalEmail.trim().length() == 0){
            throw new WebserviceUtil.NullParameterException('subscriber.personalEmail', '');
        }
    }

    /** This method validates the contents of a SubscriptionsWebservices.Payment class
        BE AWARE: The method will throw exceptions if invalid data is found.
    */
    private static void validatePayment(SubscriptionsWebservices.Payment payment){
        if(payment.paymentDate == null){
            throw new WebserviceUtil.NullParameterException('payment.paymentDate', '');
        }
        if(payment.amountGross == null){
            throw new WebserviceUtil.NullParameterException('payment.amountGross', '');
        }
        if(payment.currencyType == null){
            throw new WebserviceUtil.NullParameterException('payment.currencyType', '');
        }
        if(payment.paymentStatus == null){
            throw new WebserviceUtil.NullParameterException('payment.paymentStatus', '');
        }
        if(!paymentStatuses.contains(payment.paymentStatus.toLowerCase())){
            throw new WebserviceUtil.InvalidFieldException('payment.paymentStatus', payment.paymentStatus, paymentStatuses + '');
        }
        if(payment.paymentType == null){
            throw new WebserviceUtil.NullParameterException('payment.paymentType', '');
        }
        if(!paymentTypes.contains(payment.paymentType.toLowerCase())){
            throw new WebserviceUtil.InvalidFieldException('payment.paymentType', payment.paymentType, paymentTypes + '');
        }
        if(payment.productName == null){
            throw new WebserviceUtil.NullParameterException('payment.productName', '');
        }
        if(payment.productName == 'digital' && payment.digitalSubscriptionID == null){
            throw new WebserviceUtil.NullParameterException('payment.digitalSubscriptionID', '');
        }
        if(payment.orderId == null){
            throw new WebserviceUtil.NullParameterException('payment.orderId', '');
        }
    }

    /** This method validates the contents of a SubscriptionsWebservices.Subscription class
        BE AWARE: The method will throw exceptions if invalid data is found.
    */
    private static void validateSubscription(SubscriptionsWebservices.Subscription subscription){

        if(subscription.productType == null){
            throw new WebserviceUtil.NullParameterException('subscription.productType', '');
        }
        if(!productTypes.contains(subscription.productType.toLowerCase())){
            throw new WebserviceUtil.InvalidFieldException('subscription.productType', subscription.productType, productTypes + '');
        }

        if(subscription.subscriptionType == null){
            throw new WebserviceUtil.NullParameterException('subscription.subscriptionType', '');
        }
        if(!subscriptionTypes.contains(subscription.subscriptionType.toLowerCase())){
            throw new WebserviceUtil.InvalidFieldException('subscription.subscriptionType', subscription.subscriptionType, subscriptionTypes + '');
        }

        if(subscription.startDate == null){
            throw new WebserviceUtil.NullParameterException('subscription.startDate', '');
        }
    }

    /** Process a DMLException object that only contains one exception
    *   DMLException actually wraps up multiple types of exception and
    *   not all of them have the same information available.  This is
    *   meant to handle the different flavours of DMLException in a manner
    *   that is specific to the SubscriptionsWebservices
    **/
    private static void handleSingleDMLException(DMLException ex, SObject obj){
        system.Statuscode exType = ex.getDmlType(0);

        if(exType == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION){
            throw new WebserviceUtil.DatabaseValidationException(ex.getDMLMessage(0),'');
        }

        if(exType == system.Statuscode.INVALID_FIELD ||
            exType == system.Statuscode.STRING_TOO_LONG){
            throw new WebserviceUtil.InvalidFieldException(ex.getDMLFieldNames(0)[0], (String)obj.get(ex.getDMLFieldNames(0)[0]), ex.getDMLMessage(0));
        }

        // Don't want to handle this error in a custom way - just throw it back out
        throw ex;

    }

    /***************************************************************************************
    Developer - MIrfan@Appirio
    Date - 11/05/12
    Version - 1.1
    Function -  Failed jobs for the bulk user request should pass the tsnumber, firstname, lastname and email.
    #############Change Log#############
    Wiktor Czykin   1.1         02/06/2015  //modified method signature, added map preparation and call to TMGUtil.logIndividualLogsForParent()
    ****************************************************************************************/
    public static void updateFailedUserManageRequests(Id logId, String systemEndpoint, List<SubscriptionsWebservices.FailedUserManageResult> tasks){
        if(tasks == null || tasks.size() == 0){
            throw new WebserviceUtil.NullParameterException('FailedUserManageResult[]', '');
        }

        //Task list.
        List<Task> taskQueue = new List<Task>();
        //Unique tsnumbers to match with accounts.
        Set<String> accTSNumbers = new Set<String>();
        //Store accounts that match the tsnumbers
        Map<String, Account> accMap = new Map<String, Account>();
        //maps for extra logging
        Map<Id, SubscriptionsWebservices.FailedUserManageResult> mapAccountIdToFailures = new Map<Id, SubscriptionsWebservices.FailedUserManageResult>();
        Map<Id, String> mapAccountIdToTSNumber = new Map<Id, String>();

        //Retrieve the tsnumbers to query subscribers.
        for(SubscriptionsWebservices.FailedUserManageResult a :tasks){
            accTSNumbers.add(a.tsNumber);
        }

        for(Account acc : [SELECT   Id,
                                    FirstName,
                                    LastName,
                                    Subscriber_Number_static__c,
                                    LastModifiedById,
                                    PersonEmail
                                FROM Account
                                WHERE Subscriber_Number_static__c IN :accTSNumbers]){
            accMap.put(acc.Subscriber_Number_static__c, acc);
            mapAccountIdToTSNumber.put(acc.Id, acc.Subscriber_Number_Static__c);
        }

        if(accMap.isEmpty()){
            throw new WebserviceUtil.GenericWSException('', 'No Accounts can be found from the TSNumbers provided [' + String.valueOf(accTSNumbers) + ']');
        }

        for(SubscriptionsWebservices.FailedUserManageResult a :tasks){
            Account acc = accMap.get(a.tsNumber);
            if(acc != null && acc.Id != null){
                mapAccountIdToFailures.put(acc.Id, a);
            }

            taskQueue.add(TaskHelper.createTask(
                acc.LastModifiedById, acc.Id,
                Constants.FAILED_USER_REQUEST_SUBJECT.replace('[SYSTEM]', systemEndpoint),
                Constants.FAILED_USER_REQUEST_DESCRIPTION.replace('[SYSTEM]', systemEndpoint) + '\n'
                    + (acc.FirstName != a.firstName ? 'Change first name to: ' + acc.FirstName + '\n' : '')
                    + (acc.LastName != a.lastName ? 'Change last name to: ' + acc.LastName + '\n': '')
                    + (acc.PersonEmail != a.emailAddress ? 'Change email to: ' + acc.PersonEmail + '\n': '')
                    + '\n\nExtra Details:\n' + a.message + '\n\n' + String.valueOf(a),
                Constants.FAILED_USER_REQUEST_STATUS)
            );

            if(a.firstName != null && a.firstName.length() > 0 && acc.FirstName != a.firstName){
                acc.FirstName = a.FirstName;
            }
            if(a.lastName != null && a.lastName.length() > 0 && acc.LastName != a.lastName){
                acc.LastName = a.lastName;
            }
            if(a.emailAddress != null && a.emailAddress.length() > 0 && acc.PersonEmail != a.emailAddress){
                acc.PersonEmail = a.emailAddress;
            }
        }

        if(!mapAccountIdToFailures.isEmpty()){
            TMGUtil.logIndividualLogsForParent(logId, mapAccountIdToFailures, mapAccountIdToTSNumber);
        }

        //Do the job only if the task and account queues are not empty.
        if(taskQueue.isEmpty() || accMap.isEmpty()){
            throw new WebserviceUtil.GenericWSException('', 'No tasks or accounts have been queued for the TSNumbers provided [' + String.valueOf(accTSNumbers) + ']');
        }

        //Create the tasks first.
        insert taskQueue;
        //Set the static global flag here to stop MPP callout.
        Constants.MPP_CALLOUT_DISABLED = true;
        //Update old emails back to their respected accounts.
        update accMap.values();
    }

    //MIrfan@Appirio, Plane 1.2, MPPDDSetupFailur, 110512
    //Created below 4 contants to maintain Max number and Task creation text.
    static final Integer MPP_CALLOUT_MAX_ATTEMPTS=3;
    static final Integer MPP_CALLOUT_MAX_MINUTES_WAIT=240;
    static final String FAILED_DD_SUBJECT = '[DDOperation] on [SYSTEM] Failed';
    static final String FAILED_DD_DESCRIPTION = '[DDOperation] on [SYSTEM] failed, for Offered Subscription [SUBNAME] [ADDTIONALINFO].';


    /*
        Failed jobs for the bulk DDSetup request should pass the tsnumber and message.
    */
    public static void updateFailedDirectDebitRequests(String systemEndpoint, List<SubscriptionsWebservices.FailedMPPBulkResult> lstFailedTSNumbers)
    {
        if(lstFailedTSNumbers == null || lstFailedTSNumbers.size() == 0){
            throw new WebserviceUtil.NullParameterException('FailedMPPBulkResult[]', '');
        }

        Map<String,SubscriptionsWebservices.FailedMPPBulkResult> mapFailureTSNumbers = new Map<String,SubscriptionsWebservices.FailedMPPBulkResult>();

        for(SubscriptionsWebservices.FailedMPPBulkResult rec:lstFailedTSNumbers)
        {
            if(rec.tsNumber!=null && !mapFailureTSNumbers.containsKey(rec.tsNumber))
            {
                mapFailureTSNumbers.put(rec.tsNumber,rec);
            }
        }
        System.debug('#########mapFailureTSNumbers##############'+mapFailureTSNumbers);
        string strCalloutNextStages = 'PaymentSchedule;PaymentSchedule-Failed;';

        Datetime curDateTime = System.now();

        List<Subscription__c> lstSubsToUpdate = new List<Subscription__c>();
        List<Task> lstTaskToCreate = new List<Task>();
        //MIrfan@Appirio, Task owner default to System User, PP-1578
        User taskAssignee;
        for(User usr: [SELECT Id FROM User WHERE name ='System' limit 1])
        {
            taskAssignee=usr;
        }
        system.debug('#####Task created in MPP updateFailedDirectDebitRequests#####');

        for(Subscription__c rec:[Select Id,MppDDCalloutStage__c,MppDDCalloutAttemptCount__c,MppDDLastCalloutDateTime__c,Subscriber__c,Cancellation_Method__c,
                                    LastModifiedById,Name, Subscriber__r.Subscriber_Number__c,Start_Date__c,Cancellation_Date__c ,Cancellation_Reason__c
                                 from Subscription__c
                                    where MppDDCalloutStage__c != :DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_FAILED
                                    and MppDDCalloutStage__c !=null
                                    and Subscription_Status__c in ('Offered','Pending')
                                    and Subscriber__r.Subscriber_Number__c !=null
                                    and Subscriber__r.Subscriber_Number__c =:mapFailureTSNumbers.keySet()])
        {
                    system.debug('#### DD failed in updateFailedDirectDebitRequests ####');
                    rec.MppDDCalloutStage__c = DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_FAILED;//'Failed';

                    // START : PP-1896
                    // populate the cancellation reason and the method as below
                    rec.Subscription_Status__c='Pending Cancellation';
                    rec.Cancellation_Date__c =  rec.Start_Date__c;
                    rec.Cancellation_Reason__c = 'DD Migration Failure';
                    rec.Cancellation_Method__c = 'DD Migration Failure';
                    // END : PP-1896
                    system.debug('#### DD failed in updateFailedDirectDebitRequests #### rec.Cancellation_Reason__c: '+rec.Cancellation_Reason__c+',rec.Cancellation_Method__c: '+rec.Cancellation_Method__c);
                    lstSubsToUpdate.add(rec);
                    String strSubject = FAILED_DD_SUBJECT.replace('[SYSTEM]', systemEndpoint);
                    strSubject=strSubject.replace('[DDOperation]', 'Direct Debit Setup');

                    String strDescription = FAILED_DD_DESCRIPTION.replace('[SYSTEM]', systemEndpoint);
                    strDescription=strDescription.replace('[DDOperation]', 'Direct Debit Setup');
                    strDescription=strDescription.replace('[SUBNAME]', rec.Name);
                    strDescription=strDescription.replace('[ADDTIONALINFO]', 'with Direct Debit details from linked InRenewal Subscription. With message :'+
                                            mapFailureTSNumbers.get(rec.Subscriber__r.Subscriber_Number__c).message);

        //MIrfan@Appirio, Task owner default to System User, PP-1578
                    lstTaskToCreate.add(TaskHelper.createTask(
                                    (taskAssignee!=null?taskAssignee.id:rec.LastModifiedById), rec.id,
                                    strSubject,strDescription,
                                    'Not Started'));
               // }
        }
        if(lstSubsToUpdate.size()>0)
        {
            try{
                update lstSubsToUpdate;
                if(lstTaskToCreate.size()>0)
                {
                    insert lstTaskToCreate;
                }
            }catch(Exception ex){
                system.debug('Exception########:'+ex);/*handle exception, or notify by email*/
                ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'updateFailedDirectDebitRequests', new Map<String,Object>{'lstTaskToCreate' => lstTaskToCreate,'RequestTime' => System.now()});
                TMGUtil.logWebServiceResponse(logId, ex);
        }
        }
    }

    /***************************************************************************************
    Developer - MIrfan@Appirio
    Date - 11/05/12
    Version - 1.2
    Function -   Failed jobs for the bulk PaymentSchedule request should pass the tsnumber and message.
    #############Change Log#############
    Wiktor Czykin   1.1         02/06/2015  //added map preparation and call to TMGUtil.logIndividualLogsForParent()
    Wiktor Czykin   1.2         24/06/2015  //replaced OverrideSAMUpdate__c custom setting with trigger flag specific to current transaction instead of the whole org
    Cristina Anghenie1.3    14/09/2015  //remove subscription status set to offer to prevent setting a wrong status when MPP callback takes ages
    ****************************************************************************************/
    public static void updateFailedPaymentScheduleRequests(Id logId, String systemEndpoint, List<SubscriptionsWebservices.FailedMPPBulkResult> lstFailedTSNumbers){
        if(lstFailedTSNumbers != null && lstFailedTSNumbers.size() > 0){
            Map<String,SubscriptionsWebservices.FailedMPPBulkResult> mapFailureTSNumbers = new Map<String,SubscriptionsWebservices.FailedMPPBulkResult>();

            for(SubscriptionsWebservices.FailedMPPBulkResult rec:lstFailedTSNumbers){
                if(rec.tsNumber!=null && !mapFailureTSNumbers.containsKey(rec.tsNumber)){
                    mapFailureTSNumbers.put(rec.tsNumber,rec);
                }
            }

            System.debug('#########mapFailureTSNumbers##############'+mapFailureTSNumbers);
            Datetime curDateTime = System.now();

            List<Subscription__c> lstSubsToUpdate = new List<Subscription__c>();
            List<Task> lstTaskToCreate = new List<Task>();

            //MIrfan@Appirio, Task owner default to System User, PP-1578
            User taskAssignee;
            for(User usr: [SELECT Id FROM User WHERE name ='System' limit 1]){
                taskAssignee=usr;
            }

            Map<Id, Object> mapSubscriptionIdToPayload = new Map<Id, Object>();
            Map<Id, String> mapSubscriptionIdToTsNumber = new Map<Id, String>();

            for(Subscription__c rec:[select Id,
                                            Name,
                                            MppDDCalloutStage__c,
                                            MppDDCalloutAttemptCount__c,
                                            MppDDLastCalloutDateTime__c,
                                            Subscriber__c,
                                            LastModifiedById,
                                            Subscriber__r.Subscriber_Number__c,
                                            Previous_Subscription__r.Subscription_Status__c
                                        from Subscription__c where MppDDCalloutStage__c != :DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_FAILED
                                        and MppDDCalloutStage__c !=null
                                        and Subscription_Status__c in ('Offered','Pending')
                                        and Subscriber__r.Subscriber_Number__c !=null
                                        and Subscriber__r.Subscriber_Number__c =:mapFailureTSNumbers.keySet()]){

                if(mapFailureTSNumbers.containsKey(rec.Subscriber__r.Subscriber_Number__c) && mapFailureTSNumbers.get(rec.Subscriber__r.Subscriber_Number__c) != null){
                    mapSubscriptionIdToPayload.put(rec.Id , mapFailureTSNumbers.get(rec.Subscriber__r.Subscriber_Number__c));
                    mapSubscriptionIdToTsNumber.put(rec.Id, rec.Subscriber__r.Subscriber_Number__c);
                }

                if(!rec.Previous_Subscription__r.Subscription_Status__c.equalsIgnoreCase(DDSetupOnMPPBatch.SUBSCRIPTION_STATUS_LAPSED)){
                    if(rec.MppDDCalloutAttemptCount__c<=MPP_CALLOUT_MAX_ATTEMPTS &&
                        (curDateTime.minute() - rec.MppDDLastCalloutDateTime__c.minute())<=MPP_CALLOUT_MAX_MINUTES_WAIT){

                        rec.MppDDCalloutStage__c=DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_3_FAILED;//'PaymentSchedule-Failed';
                        lstSubsToUpdate.add(rec);
                    } else {
                        rec.MppDDCalloutStage__c = DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_FAILED;//'Failed';
                        rec.Subscription_Status__c='Pending Cancellation';
                        lstSubsToUpdate.add(rec);
                        String strSubject = FAILED_DD_SUBJECT.replace('[SYSTEM]', systemEndpoint);
                        strSubject=strSubject.replace('[DDOperation]', 'Payment Schedule Setup');

                        String strDescription = FAILED_DD_DESCRIPTION.replace('[SYSTEM]', systemEndpoint);
                        strDescription=strDescription.replace('[DDOperation]', 'Payment Schedule Setup');
                        strDescription=strDescription.replace('[SUBNAME]', rec.Name);
                        strDescription=strDescription.replace('[ADDTIONALINFO]', ' With message :'+
                                                mapFailureTSNumbers.get(rec.Subscriber__r.Subscriber_Number__c).message);

                        //MIrfan@Appirio, Task owner default to System User, PP-1578
                        lstTaskToCreate.add(TaskHelper.createTask(
                                        (taskAssignee!=null?taskAssignee.id:rec.LastModifiedById), rec.id,
                                        strSubject,strDescription,
                                        'Not Started'));

                    }
                } else {//For Lapsed Sub, Payment Schedule failure, simply create Task against System user with failure note.
                    rec.MppDDCalloutStage__c=DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_4_FAILED;//'LapsedSubPaymentSchedule-Failed';
                    lstSubsToUpdate.add(rec);
                    String strSubject = FAILED_DD_SUBJECT.replace('[SYSTEM]', systemEndpoint);
                    strSubject=strSubject.replace('[DDOperation]', 'Lapsed Sub Payment Schedule Setup');

                    String strDescription = FAILED_DD_DESCRIPTION.replace('[SYSTEM]', systemEndpoint);
                    strDescription=strDescription.replace('[DDOperation]', 'Lapsed Sub Payment Schedule Setup');
                    strDescription=strDescription.replace('[SUBNAME]', rec.Name);
                    strDescription=strDescription.replace('[ADDTIONALINFO]', ' With message :'+
                                            mapFailureTSNumbers.get(rec.Subscriber__r.Subscriber_Number__c).message);

                    //MIrfan@Appirio, Task owner default to System User, PP-1578
                    lstTaskToCreate.add(TaskHelper.createTask(
                                    (taskAssignee!=null?taskAssignee.id:rec.LastModifiedById), rec.id,
                                    strSubject,strDescription,
                                    'Not Started'));
                }
            }

            TMGUtil.logIndividualLogsForParent(logId, mapSubscriptionIdToPayload, mapSubscriptionIdToTsNumber);

            System.debug('#########lstSubsToUpdate##############'+lstSubsToUpdate);
            SubscriptionTriggerHandler.getInstance().bRunAPI = false;
            try{
                if(lstSubsToUpdate.size()>0){
                    update lstSubsToUpdate;
                }

                if(lstTaskToCreate.size()>0){
                    insert lstTaskToCreate;
                }
            }catch(Exception ex){
                System.debug('Exception########:'+ex);/*handle exception, or notify by email*/
                ID errlogId = TMGUtil.logWebServiceRequest('Inbound', null, 'updateFailedPaymentScheduleRequests', new Map<String,Object>{'lstTaskToCreate' => lstTaskToCreate,'RequestTime' => System.now()});
                TMGUtil.logWebServiceResponse(errlogId, ex);
            }
            SubscriptionTriggerHandler.getInstance().bRunAPI = true;
        } else {
            if(logId!=null){
                TMGUtil.logWebServiceDetail(logId,'No Failed payment schedule details received . Exiting without changing anything');
            }
        }
    }

    public static Pricing_Options__c getPricingOptionsByServiceIDs(String sServiceId, String sServicePriceId, String sPromoName){
        Pricing_Options__c pricingOptions = null;

        try{
            if(String.isNotEmpty(sPromoName) && String.isNotEmpty(sServiceId) && sServiceId.isNumeric() && String.isNotEmpty(sServicePriceId)){
                Integer iServiceIdNum = Integer.valueOf(sServiceId);
                Integer iServicePriceIdNum = Integer.valueOf(sServicePriceId);
                pricingOptions = [select    Id,
                                            Name,
                                            ServiceId__c,
                                            ServicePriceId__c,
                                            Dynamic_Price__c,
                                            Flow_Type__c,
                                            Subscription_Type__c,
                                            Multi_User_Discount_Voucher__c,
                                            Payment_Required__c,
                                            Package_Name__c,
                                            Product_Type__c,
                                            imageURL__c,
                                            TCodemanagement__r.Name,
                                            Show_Cancel_Button__c,
                                            Display_Expiry_Date__c,
                                            tandcURL__c ,
                                            TCode_Product__r.Product__c
                                        from Pricing_Options__c
                                        where ServiceId__c =: iServiceIdNum
                                        and ServicePriceId__c  =: iServicePriceIdNum
                                        and Package_Name__c =: sPromoName
                                        limit 1];
            }
        }catch(System.QueryException e){
            System.debug('No Pricing options found');
        }

        return pricingOptions ;

    }

    /* START : Subscriptions */
    /**
     * A helper method to udpate the Account and Subscription records as passed in the callback method
     * SubscriptionsWebservices#processPaymentScheduleSetupSuccess()
     *
     * The method updates the following fields:
     * On Account
     * MPP Renewal Pay Schedule Start Date ~ Will map to Subscriptions.PaymentSchedules paymentDate field
     * MPP Renewal Pay Schedule End Date ~ Will map to Subscriptions.PaymentSchedules endDatePaymentSchedule field
     *
     * On Subscription
     * MPP Renewal Pay Schedule Start Date ~ Will map to Subscriptions.PaymentSchedules paymentDate field
     * MPP Renewal Pay Schedule End Date ~ Will map to Subscriptions.PaymentSchedules endDatePaymentSchedule field
     *
     * @param pymntSchedules    a list of SubscriptionsWebservices.PaymentSchedules objects sent by MPP
     *
     *  #############Change Log#############
     *  Modified by     Version     Change Date
     *  Wiktor Czykin   1.1         02/06/2015  //added logic to store PaymentSchedules response in splitted manner
     *  Wiktor Czykin   1.2         24/06/2015  //added error tracking for salesforce updates failure. added support for partial success on subscriber.
     *                                          //added Webservice_Log__c details population to the end of the method.
     *                                          //replaced OverrideSAMUpdate__c custom setting with trigger flag specific to current transaction instead of the whole org
     *                                          //replaced view vars with constants
     */
    public static void updateSuccessPaymentScheduleSetup(Id logId, List<SubscriptionsWebservices.PaymentSchedules> listPaymentSchedules) {
        String payScheduleData='';
        List<String> lstExtraDetails = new List<String>();
        if(listPaymentSchedules != null || listPaymentSchedules.size() > 0){
            try{
                lstExtraDetails.add('Number of paymentSchedules received :'+listPaymentSchedules.size());

                Map<String, SubscriptionsWebservices.PaymentSchedules> tsNumberRecMap = new Map<String, SubscriptionsWebservices.PaymentSchedules>();
                // iterate through the list and prepare a map of tsNumbers and the record for further processing
                for(SubscriptionsWebservices.PaymentSchedules pymntSchedules : listPaymentSchedules) {
                    if(pymntSchedules.TSNumber != null && !tsNumberRecMap.containsKey(pymntSchedules.TSNumber)) {
                        tsNumberRecMap.put(pymntSchedules.TSNumber, pymntSchedules);
                        payScheduleData+=pymntSchedules;
                    }
                }

                // retrieve the accounts now for update
                SubscriptionsWebservices.PaymentSchedules tempRec;
                List<Account> updateAccountList = new List<Account>();
                for(Account subscriber : [select    Id,
                                                    Subscriber_Number_static__c,
                                                    IsUsingMPP__c,
                                                    MPP_CurrentPayScheduleEndDate__c,
                                                    MPP_Renewal_Pay_Schedule_Start_Date__c,
                                                    MPP_Renewal_Pay_Schedule_End_Date__c
                                          from Account
                                          where Subscriber_Number_static__c in :tsNumberRecMap.keySet()]) {

                    // fetch the result object passed by MPP
                    tempRec = tsNumberRecMap.get(subscriber.Subscriber_Number_static__c);
                    // update the fields in consideration and add to update list
                    subscriber.MPP_Renewal_Pay_Schedule_Start_Date__c = tempRec.paymentDate;
                    subscriber.MPP_Renewal_Pay_Schedule_End_Date__c = TMGUtil.isDataValid(tempRec.endDatePaymentSchedule) ? TMGDateExtension.getPaymentCollectionDate((tempRec.endDatePaymentSchedule).date()) : tempRec.endDatePaymentSchedule;
                    subscriber.IsUsingMPP__c = true;

                    updateAccountList.add(subscriber);
                }
                //fail last account in list if test run and TESTFAIL is true
                if(TESTFAILACCOUNT_LAST && Test.isRunningTest() && updateAccountList.size()>1){
                    updateAccountList[updateAccountList.size()-1].Site = 'more than 80 characters Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac tortor posuere';
                }
                lstExtraDetails.add('Number of accounts retrieved :'+updateAccountList.size());

                // retrieve the subscriptions now for update
                /* pick all those offered subs which are associated with the ts number and
                 * - check if it satisfies MPP Callout Stage 3 or MPP Callout Stage 5 failed, update that record
                 * - if does not satisfy above condition, check if MPP Callout Stage is NOT NULL, update that record
                 * - if none of the above conditions are satisfied, pick the one created by Interface User, update that record
                 * - if none of the aforesaid criteria matches, through exception, rollback any operation on account also (handled in WS)
                 */
                User userRec = [select Id, Name from User where Name = :Label.InterfaceUserName limit 1];
                Boolean found = false;
                Map<String,Subscription__c> tsNumberWithOfferedSub = new Map<String,Subscription__c>();
                List<Subscription__c> updateSubsList = new List<Subscription__c>();
                List<Subscription__c> offeredSubs=[select   Id,
                                                            Subscriber__c,
                                                            Subscriber__r.Subscriber_Number_static__c,
                                                            Payment_Type__c,
                                                            MPP_Pay_Schedule_Start_Date__c,
                                                            MPP_Pay_Schedule_End_Date__c,
                                                            MppDDCalloutStage__c,
                                                            MPP_CC_Next_Payment_Date__c,
                                                            MPP_DD_Next_Payment_Date__c,
                                                            CreatedById,
                                                            MPP_Scheduled_First_Payment_Date__c,
                                                            Total_Price__c
                                                        from Subscription__c
                                                        where Subscription_Status__c = 'Offered'
                                                        and Subscriber__r.Subscriber_Number_static__c
                                                        in :tsNumberRecMap.keySet()];
                for(Subscription__c sub : offeredSubs) {
                    if(sub!=null &&(sub.MppDDCalloutStage__c != null || sub.CreatedById == userRec.Id)){
                        Subscription__c curSub=tsNumberWithOfferedSub.get(sub.Subscriber__r.Subscriber_Number_static__c);
                        if(curSub==null){
                            System.debug('PP-1615 : Offered Sub with MPPCallout NOT NULL or created by Interface user being used as default for update - ' + sub.Id);
                            tsNumberWithOfferedSub.put(sub.Subscriber__r.Subscriber_Number_static__c,sub);
                        }else{
                            // check if the record satisfies the criteria
                            if(sub.MppDDCalloutStage__c == Constants.MPP_DDCALLOUT_STAGE_3 || sub.MppDDCalloutStage__c == Constants.MPP_DDCALLOUT_STAGE_5_FAILED){
                                System.debug('PP-1615 : Chosing offered Sub with MPPCallout Stage 3 or 5 Failed for update - ' + sub.Id);
                                tsNumberWithOfferedSub.put(sub.Subscriber__r.Subscriber_Number_static__c,sub);
                            }
                        }
                    }
                }
                lstExtraDetails.add('Number of offered subscriptons retrieved :'+tsNumberWithOfferedSub.size());

                Map<Id,Object> mapSubscriptionIdToPayload = new Map<Id, Object>();
                Map<Id,String> mapSubscriptionIdToTsNumber = new Map<Id, String>();

                for(Subscription__c sub : tsNumberWithOfferedSub.values()) {

                    mapSubscriptionIdToTsNumber.put(sub.Id, sub.Subscriber__r.Subscriber_Number_static__c);
                    if(tsNumberRecMap.containsKey(sub.Subscriber__r.Subscriber_Number_static__c)){
                        mapSubscriptionIdToPayload.put(sub.Id, tsNumberRecMap.get(sub.Subscriber__r.Subscriber_Number_static__c));
                    }
                    // fetch the result object passed by MPP
                    tempRec = tsNumberRecMap.get(sub.Subscriber__r.Subscriber_Number_static__c);
                    System.debug('PP-1615 : Iterating Payment Schedule record - '+sub.Id+';'+ tempRec);

                    // update the fields in consideration and add to update list
                    sub.MPP_Pay_Schedule_Start_Date__c = tempRec.paymentDate;
                    sub.MPP_Pay_Schedule_End_Date__c = TMGUtil.isDataValid(tempRec.endDatePaymentSchedule) ? TMGDateExtension.getPaymentCollectionDate(tempRec.endDatePaymentSchedule.date()) : tempRec.endDatePaymentSchedule;

                    // change the MPP DD callout stage to stage 4, subscription status to pending and
                    // associate the payment schedule id to mpp premium sub id
                    sub.MppDDCalloutStage__c = Constants.MPP_DDCALLOUT_STAGE_4;
                    sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
                    sub.MPP_Premium_Subscription_ID__c = tempRec.paymentScheduleId;

                    // FIXME : To be revised.
                    // for the time being update the MPP DD or CC Next Payment Date with the paymentDate in the PaymentSchedule
                    // changing default to 1 i.e making Annual as default to ensure devide by zero error do not happen
                    Integer billingFrequency = 1;
                    if(Constants.DD_COL_FREQ_MONTHLY.equalsIgnoreCase(tempRec.frequency)) {
                        billingFrequency = 12;
                    } else if (Constants.DD_COL_FREQ_QUARTERLY.equalsIgnoreCase(tempRec.frequency)) {
                        billingFrequency = 4;
                    }

                    // calculate the firstPaymentAmount to be populated
                    // divide the PaymentSchedule.totalAmount by billing frequency
                    // add any remainder to the amount, update based on the payment type below
                    Decimal firstPaymentAmount = 0;
                    if('Salesforce'.equalsIgnoreCase(Label.FirstPaymentAmountCalculation)) {
                        if(billingFrequency != 0) {
                            decimal totalAmt=tempRec.totalAmount;
                            if(totalAmt==null)
                                totalAmt=sub.Total_Price__c;
                            Decimal monthlyAmount = totalAmt / billingFrequency;
                            Decimal equatedMonthly = monthlyAmount.setScale(2, System.RoundingMode.FLOOR);
                            Decimal remainder = monthlyAmount - equatedMonthly;
                            Decimal adjustmentAmount = remainder * billingFrequency;
                            firstPaymentAmount = equatedMonthly + adjustmentAmount;
                            System.debug('PP-1615 retrieving first payment amount from Salesforce logic : '
                                            + 'Total Amount[' + tempRec.totalAmount
                                            + ']. Billing Frequency [' + tempRec.frequency + ']'
                                            + ']. Monthly Amount [' + monthlyAmount
                                            + ']. Equated Monthly Amount [' + equatedMonthly
                                            + ']. Remainder [' + remainder
                                            + ']. Adjustment Amount [' + adjustmentAmount
                                            + ']. First Payment Amount [' + firstPaymentAmount);
                        }
                    } else if('MPP'.equalsIgnoreCase(Label.FirstPaymentAmountCalculation)) {
                        firstPaymentAmount = tempRec.paymntOrders.amount;
                        System.debug('PP-1615 retreiving first payment amount from MPP logic - ' + firstPaymentAmount);
                    }


                    if(Constants.SUB_PMETHOD_DD.equalsIgnoreCase(sub.Payment_Type__c)) {
                        sub.MPP_DD_Next_Payment_Date__c = sub.MPP_Scheduled_First_Payment_Date__c;

                        if(firstPaymentAmount == 0) {
                            firstPaymentAmount = sub.MPP_DD_First_Payment_Amount__c;
                        }
                        sub.MPP_DD_First_Payment_Amount__c = firstPaymentAmount;
                    } else {
                        sub.MPP_CC_Next_Payment_Date__c = sub.MPP_Scheduled_First_Payment_Date__c;

                        if(firstPaymentAmount == 0) {
                            firstPaymentAmount = sub.MPP_CC_First_Payment_Amount__c;
                        }
                        sub.MPP_CC_First_Payment_Amount__c = firstPaymentAmount;
                    }
                    updateSubsList.add(sub);
                }
                //store logs - try to match against individual requests (and set them as parents), else sets Parent_Log__c to logId passed in here from SubscriptionWebservices.processPaymentScheduleSetupSuccess()
                TMGUtil.logIndividualResponsesForIndividualRequests(mapSubscriptionIdToPayload, mapSubscriptionIdToTsNumber, Constants.LOG_PAYMENTSCHEDULE_CALLBACK+Constants.LOG_CHILD_RECORD_SUFFIX, logId);

                // update both account and subscriptions now
                String sAccountUpdateErrors = '';
                Set<Id> setSuccessfulAccountUpdates = new Set<Id>();

                AccountTriggerHandler.getInstance().bRunAPI = false;
                SubscriptionTriggerHandler.getInstance().bRunAPI = false;
                if(updateAccountList.size() > 0) {
                    List<Database.SaveResult> lstResult = Database.update(updateAccountList, false);
                    for(Integer i = 0; i < lstResult.size(); i++){
                        if(lstResult[i].isSuccess()){
                            setSuccessfulAccountUpdates.add(lstResult[i].getId());
                        }else{
                            for(Database.Error err : lstResult[i].getErrors()){
                                sAccountUpdateErrors += Label.MPP_Communication_Callback_account_record_update_failure + updateAccountList[i].Id + ' : '+err.getMessage()+'/n';
                            }
                        }
                    }
                }
                if(String.isNotBlank(sAccountUpdateErrors)){
                    lstExtraDetails.add(sAccountUpdateErrors);
                }
                String sNotUpdatedSubscription = '';
                if(updateSubsList.size() > 0) {
                    if(Test.isRunningTest() &&  TESTFAILSUBSCRIPTION_ALL){
                        for(Subscription__c sub : updateSubsList){
                            sub.Discount__c = 1234566776;
                        }
                    }
                    //only update subscriptions for successful account updates
                    for(Integer i = 0; i < updateSubsList.size(); i++){
                        if(!setSuccessfulAccountUpdates.contains(updateSubsList[i].Subscriber__c)){
                            sNotUpdatedSubscription += Label.MPP_Communication_Callback_subscription_update_failure_because_of_account+updateSubsList[i].Id;
                            updateSubsList.remove(i);
                            i--;
                        }
                    }
                    update updateSubsList;
                } else {
                    if(logId!=null){
                        try{
                            TMGUtil.logWebServiceDetail(logId,'No offered subscription record found. Account will also not be updated.');
                            TMGUtil.logWebServiceAttachment(logId, 'Inbound', 'MPP', Constants.LOG_PAYMENTSCHEDULE_CALLBACK,'PaymentSchedules_noOfferedSub','text/plain',Blob.valueOf(payScheduleData));
                        }catch(Exception ex){
                            System.debug('PP-1615 : Error while attaching file to logs');
                        }
                    }
                }
            } catch(Exception ex){
                System.debug('exception in subshandlers.updatesuccessPayschedule : '+ex.getMessage()+' thrown from: '+ex.getLineNumber() + ' stackTrace: '+ex.getStackTraceString());
                lstExtraDetails.add(ex.getMessage());
            }
        }else{
           lstExtraDetails.add('No payment schedules received. Exiting without changing anything.');
        }
        if(logId!=null && !lstExtraDetails.isEmpty()){
            TMGUtil.logWebServiceDetail(logId, String.join(lstExtraDetails, '\n'));
        }
        AccountTriggerHandler.getInstance().bRunAPI = true;
        SubscriptionTriggerHandler.getInstance().bRunAPI = true;
    }


    /**
     * Method to update the payment schedules on the account.
     *
     * @param tsNumber              the TS Number of the account
     * @param entryPoint            determining if the flow is from OFFLINE or ONLINE
     * @param subscriptionDetails   SubscriptionsWebservices.Subscription object, used in case of ONLINE flows to pick the payment date
     * @param paymentDetails        SubscriptionsWebservices.Payment object, used in case of OFFLINE flows to pick the payment date
     */
    public static void updatePaymentSchedulesOnAccount( String tsNumber,
                                                        String entryPoint,
                                                        SubscriptionsWebservices.Subscription subscriptionDetails,
                                                        SubscriptionsWebservices.Payment paymentDetails) {
        try {
            Account acct = [select Subscriber_Number_Static__c, MPP_Service_Id__c, Order_Taken_Date__c, MPP_CurrentPayScheduleEndDate__c
                            from Account where Subscriber_Number_Static__c = :tsNumber limit 1];

            /*
             * product type is PREMIUM and :
             * if flow is ONLINE then
             *      - fetch the payment date from subscriptionDetails
             * else if flow is OFFLINE
             *      - fetch the payment date from paymentDetails
             *      if paymentDate in paymentDetails is NULL then
             *          - fetch the nextPaymentDate from recurring info
             */
            Date paymentDate;
            if('ONLINE'.equalsIgnoreCase(entryPoint)) {
                paymentDate = subscriptionDetails.paymentDate;
                System.debug('Entry point is ONLINE flow. paymentDate fetched from Subscription details obj - ' + paymentDate);
            } else { // OFFLINE
                // do not update the Current Pay Schedule End Date for One Off payments
                Boolean isOneOffPayment = TMGUTil.isDataValid(paymentDetails.productName) && paymentDetails.productName.toLowerCase().equals('oneoffpayment');
                if(isOneOffPayment) {
                    System.debug('This is One off Payment, not updating the Current Pay Schedule End Date on Account, returning ..');
                    return;
                }

                Datetime paymentDatetime = paymentDetails.paymentDate;
                paymentDate = Date.newInstance(paymentDatetime.year(), paymentDatetime.month(), paymentDatetime.day());
                System.debug('Entry point is OFFLINE flow. paymentDate fetched from Payment details obj - ' + paymentDate);

                // if null, then fetch the nextPaymentDate from recurring info details
                if(paymentDate == null) {
                    SubscriptionsWebservices.MPPRecurringInfo recurringInfo = paymentDetails.recurringDetails;
                    paymentDate = recurringInfo.nextPaymentDate;
                    System.debug('Entry point is OFFLINE flow. paymentDate fetched from Payment details obj was NULL,'
                                 + ' fetching from MPP Recurring Info next payment date - ' + paymentDate);
                }
            }

            // current pay schedule end date would be 12 months from the start date
            paymentDate = TMGDateExtension.getPaymentCollectionDate(paymentDate);
            paymentDate = paymentDate.addMonths(12);

            System.debug('Payment Date retrieved adjusted to collection date (after adding 12 months) - ' + paymentDate);
            acct.MPP_CurrentPayScheduleEndDate__c = paymentDate;
            update acct;
        } catch (Exception e) {
            System.debug('Error while updating payment schedules on Account - ' + e.getStackTraceString());
        }
        System.debug('Exiting SubscriptionsWebservicesHandlers#updatePaymentSchedulesOnAccount()');
    }

    /** Added new method as  Part for Vodafone-100
    ** Update the details of UsageTracking for a particular subscriber
    */
     public static void updateUsageTrackingData(String vendorId, DigitalUpdateWebservices.DeviceInfo device,DigitalUpdateWebservices.EntitlementDetails entitlement,DateTime lastAccessed){

        if(vendorId == null){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        if(device == null){
            throw new WebserviceUtil.NullParameterException('device', '');
        }

        if(lastAccessed == null){
            throw new WebserviceUtil.NullParameterException('lastAccessed', '');
        }

        Map<string, Map<string,DateTime>> data = new Map<string, Map<string,DateTime>>();

        List<Account> updateAccounts = new List<Account>();
        List<Usage_Tracking__c>usage=new list<Usage_Tracking__c>();
        List<Usage_Tracking__c>usageUpdate=new list<Usage_Tracking__c>();

        Account acc;
        try{
            acc = [SELECT Id,Subscriber_Digital_Status__c,RecordTypeId,MPP_Digital_Payment_Id__c,Number_of_Active_Subscriptions__c,Number_of_In_Renewal_Subscription__c,Number_of_Pending_Subscriptions__c,Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE Subscriber_Number_Static__c = :vendorID or PersonEmail = :vendorID or Platform_Vendor_ID__c = :vendorID];
        }catch(System.QueryException qe){//Fire if no rows found
            throw new WebserviceUtil.UnknownSubscriberException(vendorID, '');
        }

        //Update Account entitlement details
        if(entitlement!=null){
            Account account=new Account(id=acc.ID);
            account.Entitlement_Identifier__c=entitlement.entitlementIdentifier;
            account.Entitlement_Type__c=entitlement.entitlementType;
            updateAccounts.add(account);
        }

        usage =  [SELECT Account__c,App_Name__c,App_Version__c,Device_Name__c,Device_Operating_System__c,Device_Type__c,
                  Device_Unique_ID__c,First_Accessed_Date__c,Id,Last_Accessed_Date__c
                  FROM Usage_Tracking__c
                  WHERE Device_Unique_ID__c = :device.deviceid
                  AND Device_Operating_System__c =:device.deviceOS
                  AND App_Name__c =:device.apps[0].appName
                  AND App_Version__c =:device.apps[0].appVersion
                  AND Account__c=:acc.ID];

        for(Usage_Tracking__c usageItem:usage){
            //Doesn't seem likely,  but,  make sure that we're only ever increasing the date
            if(usageItem.Last_Accessed_Date__c < lastAccessed){
                usageItem.Last_Accessed_Date__c = lastAccessed;
                //Added to list to Update lastAccessdate
                usageUpdate.add(usageItem);
            }
        }

        if(usage == null || usage.size() == 0){
          Usage_Tracking__c trackingInfo=new Usage_Tracking__c();
          trackingInfo.App_Name__c =device.apps[0].appName ;
          trackingInfo.App_Version__c=device.apps[0].appVersion;
          trackingInfo.Device_Unique_ID__c=device.deviceid;
          trackingInfo.Device_Operating_System__c=device.deviceOS;
          trackingInfo.Device_Name__c=device.deviceName;
          trackingInfo.Device_Type__c=device.devicetype;
          trackingInfo.First_Accessed_Date__c=lastAccessed;
          trackingInfo.Last_Accessed_Date__c=lastAccessed;
          trackingInfo.Account__c=acc.Id;
          //Added to list to create new Record
          usageUpdate.add(trackingInfo);
        }

        try{
           if(usageUpdate.size()>0)
               upsert usageUpdate;

           if(updateAccounts.size()>0)
               update updateAccounts;
        }catch(DMLException ex){
            handleSingleDMLException(ex, usageUpdate[0]);
        }
    }

    public static string correctFormatOfDigitalSubscriberStatus(String currentDigitalSubscriberStatus){
        String newDigitalSubscriberStatus;
        //FirstClarity have been passing inconsistent values in Digital Subscriber Status. This code will ensure that value is in correct format
        if (currentDigitalSubscriberStatus.toLowercase() == 'active')
            newDigitalSubscriberStatus = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;

        if (currentDigitalSubscriberStatus.toLowercase() == 'inactive')
            newDigitalSubscriberStatus = Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE;

        return newDigitalSubscriberStatus;
    }

    public static Pricing_Options__c getPricingOptionByName(String pricingOptionName){
        List<Pricing_Options__c> lstPricingOptions = [select    Id,
                                                                Name,
                                                                ServiceId__c,
                                                                ServicePriceId__c,
                                                                Dynamic_Price__c,
                                                                Flow_Type__c,
                                                                Subscription_Type__c,
                                                                Multi_User_Discount_Voucher__c,
                                                                Payment_Required__c,
                                                                Package_Name__c,
                                                                Product_Type__c,
                                                                imageURL__c,
                                                                TCodemanagement__r.Name,
                                                                Show_Cancel_Button__c,
                                                                Display_Expiry_Date__c,
                                                                tandcURL__c
                                                            from Pricing_Options__c
                                                            where Name = :pricingOptionName limit 1];
        if(lstPricingOptions.isEmpty()){
            System.debug('No Pricing options found.');
            return null;
        }
        return lstPricingOptions[0];
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2016
    Version - 1.0
    Function - overloaded method to support different params for Subscriber preparation - Account Id
    #############Change Log#############
    ****************************************************************************************/
    public static void setEntitlements(Id accountId){
        if(accountId != null){
            List<SubscriberPortal.Subscriber> lstSub = SubscriberPortal.getSubscribers(new Set<Id>{accountId});
            if(!lstSub.isEmpty()){
                setEntitlements(lstSub[0]);
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2016
    Version - 1.0
    Function - overloaded method to support different params for Subscriber preparation - TSNumber and Postcode
    #############Change Log#############
    ****************************************************************************************/
    public static void setEntitlements(String sTSNumber, String sPostCode){
        if(String.isNotBlank(sTSNumber) && String.isNotBlank(sPostCode)){
            SubscriberPortal.Subscriber sub = SubscriberPortal.getSubscriber(sTSNumber, sPostCode);
            if(sub!=null){
                setEntitlements(sub);
            }
        }
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 24.05.2016
    Version - 1.0
    Function - method that set entitlements using SubscriberEntitlementsQueueable
    #############Change Log#############
    ****************************************************************************************/
    public static void setEntitlements(SubscriberPortal.Subscriber sub) {
        if(sub == null) return;

        String SAMServiceKey = PlaneURL__c.getInstance('SAM').Login__c;
        List<SubscriptionsSAMWebservices.updateNotification> payloadwithEntitlements = new List<SubscriptionsSAMWebservices.updateNotification>();
        if(sub.guid != null) {
            SubscriptionsSAMWebservices.attributes_element attrs = new SubscriptionsSAMWebservices.attributes_element();
            String value = extractValue(sub.attributes, 'EMAIL_ADDRESS');
            if(value != null){
                attrs.email = new SubscriptionsSAMWebservices.emailAttribute();
                attrs.email.value = value;
            }

            SubscriptionsSAMWebservices.updateNotification subUpdate = new SubscriptionsSAMWebservices.updateNotification();
            if(sub.entitlements.size() > 0){
                subUpdate.entitlements = String.join(sub.entitlements, ',');
            }else{
                subUpdate.entitlements = null;
            }

            subUpdate.guid = sub.guid;
            subUpdate.pid = sub.pid;
            subUpdate.samServiceKey = SAMServiceKey;
            subUpdate.timeStamp = DateTime.now();
            subUpdate.attributes = attrs;
            payloadwithEntitlements.add(subUpdate);

            System.enqueueJob(new SubscriberEntitlementsQueueable(200,payloadwithEntitlements,0));
        }
    }
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 24.05.20165
    Version - 1.0
    Function - helper method rande
    #############Change Log#############
    ****************************************************************************************/
    private static String extractValue(List<SubscriberPortal.KeyValuePair> pairs, String key){
            for(SubscriberPortal.KeyValuePair kvp : pairs){
                if(kvp.key == key)
                    return (kvp.value == null || kvp.value.length() == 0) ? null : kvp.value;
            }
            return null;
    }
}
