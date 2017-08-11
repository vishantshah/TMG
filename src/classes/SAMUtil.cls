/**
* @author Unknown
* @date Unknown
* @description Class that calls SAM WebServices
* Deals with Logs and Exception
#############Change Log#############
Modified by         Change Date
Wiktor Czykin       16/09/2015  //modified setupSAMData() - constants
Wiktor Czykin       07/01/2016  //modified one version of updateSamAccount() to support bulk logging, added class extension
Pawel Chrzanowski   11/03/2016  //modified setupSAMData() to not change entitlements on email update
Pawel Chrzanowski   17/03/2016  //removed isEmailUpdate and modified entitlement setup
Michal Szewczyk     19/04/2016  //modified setupSAMData() - entitlements
Michal Szewczyk     09/05/2016  //modified both updateSamAccount and  setupSAMData()
Pawel Chrzanowski   19/05/2016  //modified updateSamAccount - optional SubscriberEntitlementsQueueable
Wiktor Czykin       25/05/2016  //modified createSamAccount()
Michal Szewczyk     28/11/2016  //modified isExistingSamAccount() , getExistingSAMAccount()
Michal Szewczyk     10/12/2016  //modified createSamAccount() 
Wiktor Czykin       20/07/2017  //added createSamAccount() future method and checkEmailInSAM()
**/
global class SAMUtil extends BulkLoggerCommon{

    @TestVisible private static Boolean bTestSamCreation = false;
    
    // Digital entitltement
    public final String DIGITAL_ENT_ACTIVE = 'DIGITAL_SUBSCRIBER_ACTIVE';
    public final String PREMIUM_ENT_ACTIVE = '7DAY_SUBSCRIBER_ACTIVE';
    public final String PREMIUM_ENT_PENDING = '7DAY_SUBSCRIBER_PENDING';

    public SubscriptionsSAMWebservices.SalesforceServiceImplPort fcWebService;
    public String SAMServiceKey;
    public String SAM_URL;

    public SAMUtil(){
        super(SAMUtil.class.getName());
        // Getting the SAM Service Key from Custom Setting
        this.SAMServiceKey = PlaneURL__c.getInstance('SAM').Login__c;
        // Getting the SAM URL from Custom Setting
        this.SAM_URL = PlaneURL__c.getInstance('SAM').URL__c;
        // Init the WebService Class
        this.fcWebService = new SubscriptionsSAMWebservices.SalesforceServiceImplPort();
        // IMPORTANT: setting up the endpoint
        this.fcWebService.endpoint_x = this.SAM_URL;
    }

    /*
    * Check if this email exists in SAM
    */
    public String isExistingSamAccount(String email){
        // Validation
        if(email == null || email == ''){
            throw new WebserviceUtil.NullParameterException('email', '');
        }
        SubscriptionsSAMWebservices.salesforceResponse response;
        if (!Test.isRunningTest()){
            response = SAMInterfaceHTTP.checkExistingAccount(email);
        }else{
            response = new SubscriptionsSAMWebservices.salesforceResponse();
            response.status = 'SUCCESS';
            response.guid = 'GUID__TEST';
        }

        if(response.status == 'SUCCESS'){
            System.debug('SAM GUID: '+response.guid);
            return response.guid;
        }
        System.debug('NO SAM GUID: '+response);
        return null;
    }

    public SAMAccountResult getExistingSAMAccount(String email){
        SAMAccountResult result;
        SubscriptionsSAMWebservices.salesforceResponse response;

        if (!Test.isRunningTest()){
            // Calling the Webservice
            response = SAMInterfaceHTTP.getExistingAccount(email);

        }else{
            // Dummy response
            response = new SubscriptionsSAMWebservices.salesforceResponse();

            // changes made to accomodate ACCOUNT_LOCKED scenario for test cases
            if('ACCOUNT_LOCKED@TEST'.equals(email)) {
                response.status = 'ACCOUNT_LOCKED';
                throw new WebserviceUtil.SamException(response.status, '');
            }

            response.status = 'SUCCESS';
            response.guid = 'GUID__TEST';
            response.entitlements = new List<String>();
        }
        System.debug('### SAM RESPONSE: ' + response);

        //If SAM System is down then EventBroker will send status message "Service is unavailable, please try later."
        if(response.status!=null &&
            (response.status.toUpperCase().contains('ERROR')
                || response.status.toUpperCase().contains('UNAVAILABLE')
                || response.status.toUpperCase().equals('ACCOUNT_LOCKED'))) {
            //If status from EventBroker/SAM is not success then, there might be some failure.
            throw new WebserviceUtil.SamException(response.status,'');
        }

        result = new SAMAccountResult();
        if(response != null){
            result.guid = response.guid;
            if(response.entitlements != null){
                result.entitlements = new List<String>(response.entitlements);
                if(result.entitlements.size() > 0 ) {
                     result.entitlementStatus = 'ACTIVE';
                }
            }
        }

        result.entitlementStatus = (result.entitlementStatus != 'ACTIVE' ? 'INACTIVE' : result.entitlementStatus);
        System.debug('### RESULT: ' + result);
        return result;
    }
   
    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - callout to SAM to update account details
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         07/01/2016  //added support for bulk logging
    Michal Szewczyk     1.2         09/05/2016  //added SubscriberEntitlementsQueueable call
    ****************************************************************************************/
    public void updateSamAccount(SubscriberPortal.Subscriber subscriber, Account acc, String TSNumber, String SAMGuid, String productType, Boolean logsIsExisting){
        if(String.isBlank(TSNumber)){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }
        SubscriptionsSAMWebservices.commonRequest userDetails = this.setupSAMData(acc, TSNumber, productType);
        SubscriptionsSAMWebservices.updateNotification subUpdate = new SubscriptionsSAMWebservices.updateNotification();
        List<SubscriptionsSAMWebservices.updateNotification> subs = new List<SubscriptionsSAMWebservices.updateNotification>();
        if (subscriber.entitlements != null && subscriber.entitlements.size() > 0){
            userDetails.entitlements = null;

            subUpdate.guid = SAMGuid;
            //subUpdate.pid = userDetails.pid;
            subUpdate.samServiceKey = userDetails.samServiceKey;
            subUpdate.timeStamp = DateTime.now();
            subUpdate.entitlements = String.join(subscriber.entitlements, ',');

            SubscriptionsSAMWebservices.attributes_element attrs = new SubscriptionsSAMWebservices.attributes_element();
                    attrs.email = new SubscriptionsSAMWebservices.emailAttribute();
                    attrs.email.value = userDetails.email;
            subUpdate.attributes = attrs;
            subs.add(subUpdate);
        }



        SubscriptionsSAMWebservices.salesforceResponse response;
        if (!Test.isRunningTest()){
            response = fcWebService.updateAccount(userDetails, SAMGuid);
            System.debug('###Response: '+response);
        }else{
            response = new SubscriptionsSAMWebservices.salesforceResponse();
            response.status = 'SUCCESS';
            response.guid = 'GUID__TEST';
        }

        Map<String,Object> mapToLog = new Map<String ,Object>{  'Account' => acc,
                                                                'email' => acc.PersonEmail,
                                                                'TSNumber' => TSNumber,
                                                                'userDetails' => userDetails,
                                                                'SAMGuid' => SAMGuid
                                                            };
        // Logging call
        WebService_Log__c wl = TMGUtil.newLogWebServiceRequestSerialized(   Constants.DIRECTION_OUTBOUND,
                                                                            this.SAM_URL,
                                                                            Constants.LOG_UPDATEACCOUNT,
                                                                            mapToLog,
                                                                            null,
                                                                            null,
                                                                            null);
        TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, response);

        if(this.bUseBulkLogging){
            this.addLogToBuffer(wl);
        }else{
            TMGUtil.logWebServiceRequestSerialized(wl);
        }
        System.enqueueJob(new SubscriberEntitlementsQueueable(200,subs,0));
        if(response.status != 'SUCCESS'){
            System.debug('###Response: '+response);
            throw new WebserviceUtil.SamException(response.status, 'dummy');
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 19/05/2016
    Version - 1.0
    Function - callout to SAM to update account details with optional SubscriberEntitlementsQueueable
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void updateSamAccount(Account acc, String TSNumber, String SAMGuid, String productType, Boolean logsIsExisting){
        updateSamAccount(acc, TSNumber, SAMGuid, productType, logsIsExisting, true);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - callout to SAM to update account details
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         09/05/2016  //added SubscriberEntitlementsQueueable call
    Pawel Chrzanowski   1.2         19/05/2016  //added option to skip SubscriberEntitlementsQueueable
    ****************************************************************************************/
    public void updateSamAccount(Account acc, String TSNumber, String SAMGuid, String productType, Boolean logsIsExisting, Boolean useQueueable){
        // Validation
        if(TSNumber == null || TSNumber == ''){
            throw new WebserviceUtil.NullParameterException('TSNumber', '');
        }

        Map<String, String> samExemptExceptions = SubscriptionsWebservices.GetSAMExemptExceptions();
        SubscriptionsSAMWebservices.commonRequest userDetails = setupSAMData(acc, TSNumber, productType);
        List<SubscriptionsSAMWebservices.updateNotification> subs = new List<SubscriptionsSAMWebservices.updateNotification>();
        SubscriptionsSAMWebservices.updateNotification subUpdate = new SubscriptionsSAMWebservices.updateNotification();

        if(String.isNotBlank(userDetails.entitlements)){
            subUpdate.guid = SAMGuid;
            //subUpdate.pid = userDetails.pid;
            subUpdate.samServiceKey = userDetails.samServiceKey;
            subUpdate.timeStamp = DateTime.now();
            subUpdate.entitlements = userDetails.entitlements;

            SubscriptionsSAMWebservices.attributes_element attrs = new SubscriptionsSAMWebservices.attributes_element();
            attrs.email = new SubscriptionsSAMWebservices.emailAttribute();
            attrs.email.value = userDetails.email;
            subUpdate.attributes = attrs;
            subs.add(subUpdate);
        }
        userDetails.entitlements = null;

        SubscriptionsSAMWebservices.salesforceResponse response;
        if (!Test.isRunningTest()){
            // Calling the Webservice
            System.debug('### SAMUtil.updateSamAccount-> userDetails: ' + userDetails);
            response = fcWebService.updateAccount(userDetails, SAMGuid);
        }
        else{
            // Dummy response
            response = new SubscriptionsSAMWebservices.salesforceResponse();
            response.status = 'SUCCESS';
            response.guid = 'GUID__TEST';
        }

        if(logsIsExisting){
            // Logging call
            ID logId = TMGUtil.logWebServiceRequest('Outbound', SAM_URL, 'updateAccount', new Map<String,Object>{'Account' => acc, 'TSNumber' => TSNumber, 'SAMGuid' => SAMGuid});

            // Logging response
            TMGUtil.logWebServiceResponse(logId, response);

            // Logging call
            logId = TMGUtil.logWebServiceRequest('Outbound', SAM_URL, 'checkExistingEmail', new Map<String,Object>{'email' => acc.PersonEmail});
            // Logging the Response
            TMGUtil.logWebServiceResponse(logId, response);
        }

        if(useQueueable){
            System.enqueueJob(new SubscriberEntitlementsQueueable(200,subs,0));
        }

        if(response.status != 'SUCCESS' && !samExemptExceptions.containsKey(response.status)){
            throw new WebserviceUtil.SamException(response.status, 'dummy');
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Create SAM Account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/05/2016  //nullified entitlements because it would fail with multiple - unbundling change
    Michal Szewczyk 1.2         11/12/2016  //switched to call SAMInterfaceHTTP.createAccount
    ****************************************************************************************/
    public String createSamAccount(Account acc, String TSNumber, String productType, Boolean logsIsExisting, Boolean noLogsMode){
        Map<String, String> samExemptExceptions = SubscriptionsWebservices.GetSAMExemptExceptions();
        SubscriptionsSAMWebservices.commonRequest userDetails = setupSAMData(acc, TSNumber, productType);
        userDetails.entitlements = null;

        SubscriptionsSAMWebservices.salesforceResponse response;
        if (!Test.isRunningTest()){
            // Calling WebService
            response = SAMInterfaceHTTP.createAccount(userDetails);
        }
        else{
            // Dummy response
            response = new SubscriptionsSAMWebservices.salesforceResponse();
            response.status = 'SUCCESS';
            response.guid = 'GUID__TEST';
        }

        // We do that against CalloutException
        // The logs will be done by the Parent (SubscriptionWebservice)
        if(!noLogsMode){
            // Logging call
            ID logId = TMGUtil.logWebServiceRequest('Outbound', SAM_URL, 'createAccount', new Map<String,Object>{'Account' => acc, 'TSNumber' => TSNumber});

            // Logging response
            TMGUtil.logWebServiceResponse(logId, response);

            if(logsIsExisting){
                // Logging call
                logId = TMGUtil.logWebServiceRequest('Outbound', SAM_URL, 'checkExistingEmail', new Map<String,Object>{'email' => acc.PersonEmail});
                // Logging the Response
                TMGUtil.logWebServiceResponse(logId, response);
            }
        }
        if(response.status == 'SUCCESS'){
            System.debug('SAM GUID: '+response.guid);
            return response.guid;
        }
        else{
            if(!samExemptExceptions.containsKey(response.status)){
                throw new WebserviceUtil.SamException(response.status, 'dummy');
            }
        }
        return null;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -   Set up the Request Data for SAM WebServices
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         16/09/2015  //replaced product type check with constant
    Pawel Chrzanowski   1.2         11/03/2016  //added condition to not change entitlements on email update
    Pawel Chrzanowski   1.3         17/03/2016  //removed isEmailUpdate and modified entitlement setup
    Michal Szewczyk     1.4         19/04/2016  //set entitlements to null is they are empty (SF issue with comma)
    ****************************************************************************************/
    public SubscriptionsSAMWebservices.commonRequest setupSAMData(Account acc, String TSNumber, String productType){
        //changes for 1798 starts null check for acc

        SubscriptionsSAMWebservices.commonRequest userDetails = new SubscriptionsSAMWebservices.commonRequest();
        if(acc != NULL){
            if(acc.Salutation != NULL)
                userDetails.title = acc.Salutation;
            if(acc.LastName != NULL)
                userDetails.lastname = acc.LastName;
            if(acc.FirstName != NULL)
                userDetails.firstname = acc.FirstName;
            if(acc.PersonEmail != NULL)
                userDetails.email = acc.PersonEmail;
            System.debug('street before: '+acc.PersonMailingStreet);
            if(acc.PersonMailingStreet != NULL)
                String mailingStreet = acc.PersonMailingStreet.replaceAll('\n','|').replaceAll(',','|');
            System.debug('street after: '+acc.PersonMailingStreet);
            if(acc.PersonMailingStreet != NULL)
                userDetails.street = acc.PersonMailingStreet;
            if(acc.PersonMailingCity != NULL)
                userDetails.city = acc.PersonMailingCity;
            if(acc.PersonMailingPostalCode != NULL)
                userDetails.postcode = acc.PersonMailingPostalCode;
            if(acc.PersonMailingCountry != NULL)
                userDetails.country = acc.PersonMailingCountry;
            if(acc.PersonMailingState != NULL)
                userDetails.county = acc.PersonMailingState;
            userDetails.marketingEmailPref = (acc.TMG_Promo_Email__c == 1);
            userDetails.marketingPhonePref = (acc.TMG_Promo_Phone__c == 1);
            userDetails.marketingPostPref = (acc.TMG_Promo_Post__c == 1);
            userDetails.marketingSMSPref = (acc.TMG_Promo_SMS__c == 1);
            userDetails.marketing3rdPref = (acc.TMG_Partner_Promo_Email__c == 1);
            userDetails.subscribersOfferPref = (acc.TMG_Loyalty_Email__c == 1);
            userDetails.samServiceKey = this.SAMServiceKey;
            userDetails.tsNumber = TSNumber;

            // Setting up the Entitlements
            userDetails.subscriberType = productType;
            userDetails.entitlements = null;
            Set<Id> setIds = new Set<Id>{acc.Id};
            List<SubscriberPortal.Subscriber> subs = SubscriberPortal.getSubscribers(setIds);
            if(!subs.isEmpty() && !subs[0].entitlements.isEmpty()){
                userDetails.entitlements = String.join(subs[0].entitlements, ',');
            }
        }
        return userDetails;
    }

    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 26/11/2015
    Version - 1.0
    Function - reset subscriber password functionality
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    WebService static string resetPassword(String email, String guid){
        String result = SAMInterfaceHTTP.resetPassword(email,guid);
        if (result == Constants.SAM_SUCCESS_CODE) result = Label.Password_change_request_success;
        return result;
    }

    global class SAMAccountResult{
        webservice String guid {get;set;}
        webservice List<String> entitlements {get;set;}
        webservice String entitlementStatus {get;set;}
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 12/07/2017
    Function - method to create SAM account for new salesforce account
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   19/07/2017  //moved here from DeliverNewspaperHandler as to be used from other place as well
    ****************************************************************************************/
    @future(callout=true)
    public static void createSamAccount(Id accountId){
        SAMUtil samUtil = new SAMUtil();
        List<Account> lstSubscriber = [SELECT    Id, Salutation, LastName, FirstName, PersonEmail, PersonMailingStreet, PersonMailingCity,
                                        PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, TMG_Promo_Email__c,
                                        TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c, TMG_Partner_Promo_Email__c,
                                        TMG_Loyalty_Email__c, Subscriber_Number_static__c
                                    FROM Account 
                                    WHERE Id = :accountId];
        if(lstSubscriber.isEmpty()) return;

        String sGuid = samUtil.createSamAccount(lstSubscriber[0], lstSubscriber[0].Subscriber_Number_static__c, Constants.PRODUCT_PREMIUM.toLowerCase(), false, false);
        if(String.isNotBlank(sGuid)){
            lstSubscriber[0].Guid__c = sGuid;
            AccountTriggerHandler.getInstance().isExecuting = true;
            update lstSubscriber;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 11/07/2017
    Function - identifies if there exists account in sam for the given email and if it exists in sfdc under different email
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   20/07/2017  //moved here from DeliverNewspaperHandler as to be used from other place as well
    ****************************************************************************************/
    public static String checkEmailInSAM(String sEmail){
        SAMUtil samUtil = new SAMUtil();
        String existingSamAccountGuid = samUtil.isExistingSamAccount(sEmail);
        if(Test.isRunningTest() && bTestSamCreation){
            existingSamAccountGuid = '';
        }
        if(String.isNotBlank(existingSamAccountGuid)){
            List<Account> newGuidInSFDC = [SELECT Id FROM Account WHERE Guid__c = :existingSamAccountGuid];
            if (!newGuidInSFDC.isEmpty()){
                throw new TelegraphApplicationException(Label.DMN_duplicate_accounts_by_guid);
            }
        }
        return existingSamAccountGuid;
    }
}