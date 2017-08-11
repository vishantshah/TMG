/**
* @author Unknown
* @date Unknown
* @description  Webservice to handle subscriptions
                This is the public interface - this is what SalesForce will generate its WSDL from.  For this reason we have strongly typed
                parameters as this provides us with in built validation and the consumer of the service with a guide of what is expected to
                be passed.
                Dependencies: SubscriptionsWebservicesHandlers, WebserviceUtil
#############Change Log#############
Modified by         Change Date
Wiktor Czykin       02/06/2015 //minor modifications to processPaymentScheduleSetupSuccess(),processFailedMPPPaymentScheduleRequests(), processFailedMPPUserManageRequests(),
Wiktor Czykin       02/07/2015 //modified processPaymentScheduleSetupSuccess();
Cristina Anghenie   11/08/2015 //remove unneccesary debugs and commented out code
Cristina Anghenie   26/08/2015 //add Subscription_Duration_Picklist__c field to sub query to fix DD payment failing
Wiktor Czykin       05/10/2015 //modified CreateTransactionAndUpsertSAMAccountv2()
Wiktor Czykin       11/2015    //added GetMPPCreateSession() webservice method and its related wrappers: CreateSessionResponse, CustomPaymentParams, CreateSessionRequest
Wiktor Czykin       30/11/2015 //added remapClientCustomParams(), modified UpdateSubscriberAndCreateTransaction(), UpdateSubscriber(), CreateSubscriber(), CreateSubscriberAndTransaction()
Wiktor Czykin       15/12/2015 //modified GetMPPCreateSession(), modified CreateSessionResponse attributes
Wiktor Czykin       15/01/2016 //modified GetMPPCreateSession()
Michal Szewczyk     22/03/2016 //changes around new data model
Michal Szewczyk     04/04/2016 // removed GetMPPCreateSession() method
Michal Szewczyk     10/05/2016 //fix for POC deletion
Michal Szewczyk     24/05/2016 //modified UpdateSubscriberAndCreateTransaction()
Wiktor Czykin       27/05/2016 //modified fetchProductAndSetClientProd() and GetTCodeAndIncentives
Michal Szewczyk     02/06/2016 //fix for MPP Promo Code flow - support for old digital
Michal Szewczyk     20/07/2016 //changed fetchProductAndSetClientProd
Lynette Lim         23/09/2016 //fix SOQL query missing field Subscription_Duration_Picklist__c in CreateTransactionAndUpsertSAMAccountv2
Wiktor Czykin       12/10/2016 //added sam callout on create and update methods
Wiktor Czykin       31/01/2017 //modified callSamForUpdateAsync() method calls because of signature change 
Wiktor Czykin       13/03/2017 //modified GetTCodeAndIncentives() - dynamic product fix 
Wiktor Czykin       06/07/2017 //modified fetchProductAndSetClientProd()
**/
global class SubscriptionsWebservices {

    public static final Integer SFDC_ERROR_NUMBER = -1;
    public static final String SFDC_CREATESESSION_ERROR_RESPONSE = 'sfdcResponse';
    public static final String SAM_RESYNC_SETTING = 'Entitlements Resync for Online';
    public static final Boolean SAM_RESYNC_ENABLED;

    static{
        General__c setting = General__c.getInstance(SAM_RESYNC_SETTING);
        if(setting != null && setting.Value_Boolean__c){
            SAM_RESYNC_ENABLED = true;
        }else{
            SAM_RESYNC_ENABLED = false;
        }
    }


    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Create a new account and add a transaction history record to it
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1     30/11/2015  //modified how checkClientCustomParams() is called
    Cristina Anghenie   1.2     04/12/2105  //replace POC value sent by MPP to poc value from account
    Michal Szewczyk     1.3     22/03/2015  // changes around new data model
    Michal Szewczyk     1.4     10/05/2016 //fix for POC deletion
    Michal Szewczyk     1.5     24/05/2016 //added setEntitlements() call
    Michal Szewczyk     1.6     02/06/2016  //fix for MPP Promo Code flow and digital entitlement
    ***************************************************************************************/
    webservice static GeneralSubscriptionsWebserviceResult UpdateSubscriberAndCreateTransaction(Subscriber subscriberDetails, Subscription subscriptionDetails, Payment paymentDetails, String POC, String IncentiveId, DirectDebitInfo directDebitDetails, CustomParameter[] clientCustomParam){
        Exception ex;
        Boolean isMovedFromFixedToCont=false;
        GeneralSubscriptionsWebserviceResult result;
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'UpdateSubscriberAndCreateTransaction', new Map<String,Object>{'subscriberDetails' => subscriberDetails,
                                                                                                                                'paymentDetails' => paymentDetails,
                                                                                                                                'subscriptionDetails' => subscriptionDetails,
                                                                                                                                'POC' => POC,
                                                                                                                                'IncentiveId' => IncentiveId,
                                                                                                                                'directDebitDetails' => directDebitDetails});
        SavePoint sp = Database.setSavePoint();
        SubscriberPortal.SUB_TRIGGER_FIRED = true;
        try{
            /** In case of digital subscribers, update the digital subscription id from payment details in the subscriber
                Set promo fields in Subscriber if subscriber is digital, else in Subscription if premium */

            //run through clientCustomParams, if a PricingOptionName has been passed then take the value and assign it to PricingOptionID field. The value in this field will later be used to link an account to a PricingOption record.
            Map<String, String> mapCustomParams = remapClientCustomParams(clientCustomParam);
            zqu__ZProduct__c productInContext;
            if(subscriberDetails != null && subscriptionDetails != null){
               subscriberDetails.productId = subscriptionDetails.productType;
            }
            if (!mapCustomParams.isEmpty()){
                checkClientCustomParams(subscriberDetails, mapCustomParams);
                productInContext = fetchProductAndSetClientProd(subscriberDetails, mapCustomParams);
            }else {
                productInContext = fetchProductAndSetClientProd(subscriberDetails, null);
            }

            if(!subscriberDetails.isPrint){
                SubscriptionsWebservicesHandlers.updateSubscriber(subscriberDetails, paymentDetails, subscriptionDetails);
            } else {
                SubscriptionsWebservicesHandlers.updateSubscriber(subscriberDetails, null, subscriptionDetails);
            }

            //Check for any Offered Subscription before creating a new, as the same method is called for acquisition and renewal.
            RenewalOffer offeredSub = SubscriptionsWebservicesHandlers.getRenewalOffer(subscriberDetails.TSNumber);
            Id subId;

            if(offeredSub!=null && offeredSub.wsError==null){
                subId=offeredSub.offeredSubId;
                //Update Subscription with new details.
                Subscription__c currentSub = [select IsContinuous__c from Subscription__c where id=:subId ];
                if (!currentSub.IsContinuous__c && subscriptionDetails.subscriptionType.toLowerCase() == Constants.SUBSCRIPTIONTYPE_CONTINUOUS){
                    isMovedFromFixedToCont = true;
                }
                SubscriptionsWebservicesHandlers.updateSubscription(subId, subscriptionDetails, paymentDetails.recurringDetails, paymentDetails!=null);
            } else {
                subId = SubscriptionsWebservicesHandlers.createSubscription(subscriberDetails.TSNumber, POC, subscriberDetails.TCode, subscriptionDetails, paymentDetails.recurringDetails,productInContext);
            }

            /** In case of digital subscribers, update the digital subscription id and order id in the txn history**/
            if(!subscriberDetails.isPrint){
                SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(subscriberDetails.TSNumber, directDebitDetails, paymentDetails);
            } else { // do BAU
                SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(isMovedFromFixedToCont,subscriberDetails.TSNumber, subId, directDebitDetails);
            }

            SubscriptionsWebservicesHandlers.createSubscriberIncentive(subscriberDetails.TSNumber, subId, IncentiveId);
            if(String.isNotBlank(POC)){
                SubscriptionsWebservicesHandlers.deletePOC(POC);
            } else {
                Account[] accs = [SELECT Poc__c FROM Account WHERE Subscriber_Number_Static__c =: subscriberDetails.TSNumber limit 1];
                if (!accs.isEmpty() && String.isNotBlank(accs[0].Poc__c)){
                    SubscriptionsWebservicesHandlers.deletePOC(accs[0].Poc__c);
                }
            }

            SubscriptionsWebservicesHandlers.createTransaction(subscriberDetails.TSNumber, paymentDetails, directDebitDetails, false);

            if(subscriberDetails.isPrint){
                SubscriptionsWebservicesHandlers.updatePaymentSchedulesOnAccount(subscriberDetails.TSNumber, 'ONLINE', subscriptionDetails, null);
            }
            result = new GeneralSubscriptionsWebserviceResult();

            //Code to update Offered Subscription to Pending for Premium Continuous; 290512,
            if(offeredSub!=null && offeredSub.wsError==null && subscriptionDetails.productType!=null &&
               productInContext.Print_Product__c && subscriptionDetails.subscriptionType!=null &&
               subscriptionDetails.subscriptionType.equalsIgnoreCase('Continuous')){
                // Updating the Subscription to Pending
                Subscription__c sub = new Subscription__c(id=offeredSub.offeredSubId,Subscription_Status__c = 'Pending');
                update sub;
            }
            SubscriptionsWebservicesHandlers.setEntitlements(subscriberDetails.TSNumber,subscriberDetails.postalCode);

        } catch (WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        } catch (Exception e){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('UpdateSubscriberAndCreateTransaction', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Updates a subscriber and if a POC is passed up will delete it
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         30/11/2015  //modified how checkClientCustomParams() is called
    Michal Szewczyk     1.2         22/03/2016  //changes around new data model
    Michal Szewczyk     1.3         10/05/2016  //fix for POC deletion
    Wiktor Czykin       1.4         11/10/2016  //added call to sam update callSamForUpdateAsync()
    ***************************************************************************************/
    webservice static GeneralSubscriptionsWebserviceResult UpdateSubscriber(Subscriber subscriberDetails, String POC, CustomParameter[] clientCustomParam){
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        result = new GeneralSubscriptionsWebserviceResult();
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'UpdateSubscriber', new Map<String,Object>{'subscriberDetails' => subscriberDetails, 'POC' => POC});
        SavePoint sp = Database.setSavepoint();
        // Make sure we don't try and update SAM - this needs to be controlled
        // by a Source parameter, which needs to be added
        SubscriberPortal.SUB_TRIGGER_FIRED = true;
        try{// DM 24/05 - PP-2095 - FirstClarity have been triggering calls to this webservice unnecessarily. As a result accounts are being updated in error. The below code uses the AccountTriggerHandler class to assess if a change is actually required
            if (subscriberDetails.TSNumber != Null){
                // select all required fields from existing account
                List<Account> currentSubscriberAccountDetail = [Select Id, Salutation, RecordTypeId, LastName, FirstName, PersonEmail, POC__c,
                                                                       PersonMailingStreet,PersonMailingCity,PersonMailingPostalCode,PersonMailingCountry,
                                                                       PersonMailingState,TMG_Promo_Email__c,TMG_Promo_Phone__c,TMG_Promo_Post__c,
                                                                       TMG_Promo_SMS__c,TMG_Partner_Promo_Email__c,TMG_Loyalty_Email__c,Subscriber_Digital_Status__c,
                                                                       Subscription_Status__c
                                                                from Account
                                                                where Subscriber_Number_Static__c = :subscriberDetails.TSNumber];
                // load webservice values into a new Account object, ready for comparison
                List<Account> inboundSubscriberDetails = new List<Account>();
                Account acc= new Account();
                acc.Salutation = subscriberDetails.title;
                acc.LastName  = subscriberDetails.lastName;
                acc.FirstName = subscriberDetails.firstName;
                acc.PersonEmail = subscriberDetails.personalEmail;
                acc.PersonMailingStreet = subscriberDetails.street;
                acc.PersonMailingCity = subscriberDetails.city;
                acc.PersonMailingPostalCode = subscriberDetails.postalCode;
                acc.PersonMailingCountry = subscriberDetails.country;
                acc.PersonMailingState = subscriberDetails.county;
                acc.TMG_Promo_Email__c  = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingEmailPref);
                acc.TMG_Promo_Phone__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingPhonePref);
                acc.TMG_Promo_Post__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingPostPref);
                acc.TMG_Promo_SMS__c = UtilitiesForSubscriptions.convertBooleanToInteger(subscriberDetails.marketingSMSPref);
                acc.Subscriber_Digital_Status__c  = subscriberDetails.digitalSubscriberStatus;

                // the below fields are not passed in from the webservice, and thus need to be populated from the existing data to ensure that the checkAccountValidity call will work (as it requires these fields)
                acc.TMG_Loyalty_Email__c = currentSubscriberAccountDetail[0].TMG_Loyalty_Email__c;
                acc.TMG_Partner_Promo_Email__c = currentSubscriberAccountDetail[0].TMG_Partner_Promo_Email__c;
                acc.RecordTypeId = currentSubscriberAccountDetail[0].RecordTypeId;
                inboundSubscriberDetails.add(acc);

                // call checkAccountValidity to validate if any further changes are required
                system.debug('**** - calling checkAccountValidity - OLD = ' + currentSubscriberAccountDetail);
                system.debug('**** - calling checkAccountValidity - NEW = ' + inboundSubscriberDetails);

                Boolean updateAccount = AccountTriggerHandler.CheckAccountValidity(currentSubscriberAccountDetail, inboundSubscriberDetails);
                system.debug('**** - updateAccount = ' + updateAccount);

                if (updateAccount){
                    Map<String, String> mapCustomParams = remapClientCustomParams(clientCustomParam);

                    //DM 24/05 - PP-2095 - FirstClarity have been passing inconsistent values in Digital Subscriber Status. This code will ensure that value is in correct format//
                    subscriberDetails.digitalSubscriberStatus = SubscriptionsWebservicesHandlers.correctFormatOfDigitalSubscriberStatus(subscriberDetails.digitalSubscriberStatus);

                    // DM 30/04 - VOD-498 - run through clientCustomParams, if a PricingOptionName has been passed then take the value and assign it to PricingOptionID field. The value in this field will later be used to link an account to a PricingOption record.
                    if(subscriberDetails != null && subscriberDetails.subscriberType != null){
                       subscriberDetails.productId = subscriberDetails.subscriberType;
                    }
                    if (!mapCustomParams.isEmpty()){
                        checkClientCustomParams(subscriberDetails, mapCustomParams);
                        fetchProductAndSetClientProd(subscriberDetails, mapCustomParams);
                    }else {
                        fetchProductAndSetClientProd(subscriberDetails, null);
                    }

                    if(!mapCustomParams.isEmpty()){
                        checkClientCustomParams(subscriberDetails, mapCustomParams);
                    }

                    SubscriptionsWebservicesHandlers.updateSubscriber(subscriberDetails);
                    if(String.isNotBlank(POC)){
                        SubscriptionsWebservicesHandlers.deletePOC(POC);
                    } else if (!currentSubscriberAccountDetail.isEmpty() && String.isNotBlank(currentSubscriberAccountDetail[0].POC__c)){
                        SubscriptionsWebservicesHandlers.deletePOC(currentSubscriberAccountDetail[0].POC__c);
                    }

                    if(SAM_RESYNC_ENABLED && !currentSubscriberAccountDetail.isEmpty()){
                        UpdateSamUserDetailsBatch.callSamForUpdateAsync(new Set<Id>{currentSubscriberAccountDetail[0].Id}, true, false);
                    }
                }
            }
        } catch (WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        } catch (Exception e){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('UpdateSubscriber', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description Create a new account
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         30/11/2015  //modified how checkClientCustomParams() is called
    Cristina Anghenie   1.2         04/12/2105  //replace POC value sent by MPP to poc value from account
    Michal Szewczyk     1.3         01/04/2016  //adjust method to use new data model
    Michal Szewczyk     1.4         10/05/2016  //fix for POC deletion
    Michal Szewczyk     1.5         02/06/2016  //fix for MPP Promo Code flow and digital entitlement
    Wiktor Czykin       1.6         11/10/2016  //added callout to SAM to sync entitlements
    ***************************************************************************************/
    webservice static CreateSubscriberResult CreateSubscriber(Subscriber subscriberDetails, Subscription subscriptionDetails, MPPRecurringInfo recurringDetails, String POC, String IncentiveId, DirectDebitInfo directDebitDetails,CustomParameter[] clientCustomParam){
        Exception ex;
        CreateSubscriberResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'CreateSubscriber',
                                                new Map<String,Object>{'subscriberDetails' => subscriberDetails, 'subscriptionDetails' => subscriptionDetails, 'POC' => POC, 'IncentiveId' => IncentiveId, 'directDebitDetails' => directDebitDetails});
        Savepoint sp = Database.setSavePoint();

        // Make sure we don't try and update SAM - this needs to be controlled
        // by a Source parameter, which needs to be added
        SubscriberPortal.SUB_TRIGGER_FIRED = true;
        try{
            // Always create the subscriber, however subscription and hence subscriptionincentive may not be needed
            // Calls to create the subscription and subscriptionincentive will handle this themselves so always call them
            //run through clientCustomParams, if a PricingOptionName has been passed then take the value and assign it to PricingOptionID field. The value in this field will later be used to link an account to a PricingOption record.
            Map<String, String> mapCustomParams = remapClientCustomParams(clientCustomParam);
            zqu__ZProduct__c productInContext;
            if(subscriberDetails != null && subscriptionDetails != null){
               subscriberDetails.productId = subscriptionDetails.productType;
            }
            if(!mapCustomParams.isEmpty()){
                checkClientCustomParams(subscriberDetails, mapCustomParams);
                productInContext = fetchProductAndSetClientProd(subscriberDetails, mapCustomParams);
            }else  {
                productInContext = fetchProductAndSetClientProd(subscriberDetails, null);
            }

            String TSNumber = SubscriptionsWebservicesHandlers.createSubscriber(subscriberDetails, null, subscriptionDetails,recurringDetails);
            Id subId = SubscriptionsWebservicesHandlers.createSubscription(TSNumber, POC, subscriberDetails.TCode, subscriptionDetails, recurringDetails,productInContext);
            SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber, subId, directDebitDetails);
            SubscriptionsWebservicesHandlers.createSubscriberIncentive(TSNumber, subId, IncentiveId);


            List<Account> lstAccs = [SELECT Id, Poc__c FROM Account WHERE Subscriber_Number_Static__c =: TSNumber limit 1];
            if(String.isNotBlank(POC)){
                SubscriptionsWebservicesHandlers.deletePOC(POC);
            } else if (!lstAccs.isEmpty() && String.isNotBlank(lstAccs[0].Poc__c)){
                SubscriptionsWebservicesHandlers.deletePOC(lstAccs[0].Poc__c);
            }

            if(subscriberDetails.isPrint){
                SubscriptionsWebservicesHandlers.updatePaymentSchedulesOnAccount(TSNumber, 'ONLINE', subscriptionDetails, null);
            }
            if(SAM_RESYNC_ENABLED && !lstAccs.isEmpty()){
                UpdateSamUserDetailsBatch.callSamForUpdateAsync(new Set<Id>{lstAccs[0].Id}, true, false);
            }
            result = new CreateSubscriberResult(TSNumber);
        } catch (WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new CreateSubscriberResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        } catch (Exception e){
            Database.rollback(sp);
            result = new CreateSubscriberResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('CreateSubscriber', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    * @author Unknown
    * @date Unknown
    * @description reate a new account and add a transaction history record to it
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         30/11/2015  //modified how checkClientCustomParams() is called
    Cristina Anghenie   1.2         04/12/2105  //replace POC value sent by MPP to poc value from account
    Michal Szewczyk     1.3         01/04/2016  //adjust method to use new data model
    Michal Szewczyk     1.4         10/05/2016  //fix for POC deletion
    Michal Szewczyk     1.5         02/06/2016  //fix for MPP Promo Code flow and digital entitlement
    Wiktor Czykin       1.6         11/10/2016  //added callout to sync entitlements with SAM
    ***************************************************************************************/
    webservice static CreateSubscriberAndTransactionResult CreateSubscriberAndTransaction(  Subscriber subscriberDetails,
                                                                                            Subscription subscriptionDetails,
                                                                                            Payment paymentDetails,
                                                                                            String POC,
                                                                                            String IncentiveId,
                                                                                            DirectDebitInfo directDebitDetails,
                                                                                            CustomParameter[] clientCustomParam){
        Exception ex;
        CreateSubscriberAndTransactionResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'SubscriptionsWebservices.CreateSubscriberAndTransaction', new Map<String,Object>{'subscriberDetails' => subscriberDetails,
                                                                                                                                                    'paymentDetails' => paymentDetails,
                                                                                                                                                    'subscriptionDetails' => subscriptionDetails,
                                                                                                                                                    'POC' => POC, 'IncentiveId' => IncentiveId,
                                                                                                                                                    'Custom Params' => clientCustomParam});
        Savepoint sp = Database.setSavePoint();
        SubscriberPortal.SUB_TRIGGER_FIRED = true;
        try{
            //run through clientCustomParams, if a PricingOptionName has been passed then take the value and assign it to PricingOptionID field. The value in this field will later be used to link an account to a PricingOption record.
            Map<String, String> mapCustomParams = remapClientCustomParams(clientCustomParam);
            zqu__ZProduct__c productInContext;

            if(subscriberDetails != null && subscriptionDetails != null){
               subscriberDetails.productId = subscriptionDetails.productType;
            }
            if(!mapCustomParams.isEmpty()){
                checkClientCustomParams(subscriberDetails, mapCustomParams);
                productInContext = fetchProductAndSetClientProd(subscriberDetails, mapCustomParams);
            }else  {
                productInContext = fetchProductAndSetClientProd(subscriberDetails, null);
            }

            /*
             * In case of digital subscribers, update the digital subscription id from payment details in the subscriber
             * Set promo fields in Subscriber if subscriber is digital, else in Subscription if premium
             */
            String TSNumber = null;
            SubscriptionsWebservices.MPPRecurringInfo recurringDetails=paymentDetails.recurringDetails;
            if(!subscriberDetails.isPrint) {
                TSNumber = SubscriptionsWebservicesHandlers.createSubscriber(subscriberDetails, paymentDetails, subscriptionDetails,recurringDetails);
            } else {
                TSNumber = SubscriptionsWebservicesHandlers.createSubscriber(subscriberDetails, null, subscriptionDetails,recurringDetails);
            }
            Id subId = SubscriptionsWebservicesHandlers.createSubscription(TSNumber, POC, subscriberDetails.TCode, subscriptionDetails, paymentDetails.recurringDetails,productInContext);

            /*
             * In case of digital subscribers, update the digital subscription id and order id in the txn history
             */
            if(!subscriberDetails.isPrint){
                SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber, directDebitDetails, paymentDetails);
            } else { // do BAU
                SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber, subId, directDebitDetails);
            }

            SubscriptionsWebservicesHandlers.createSubscriberIncentive(TSNumber, subId, IncentiveId);

            List<Account> lstAccs = [SELECT Poc__c FROM Account WHERE Subscriber_Number_Static__c =: TSNumber limit 1];
            if(String.isNotBlank(POC)){
                SubscriptionsWebservicesHandlers.deletePOC(POC);
            } else if (!lstAccs.isEmpty() && String.isNotBlank(lstAccs[0].Poc__c)){
                SubscriptionsWebservicesHandlers.deletePOC(lstAccs[0].Poc__c);
            }

            SubscriptionsWebservicesHandlers.CreateTransaction(TSNumber, paymentDetails, directDebitDetails, false);

            if(productInContext.Print_Product__c) {
                System.debug('TMGLOG::SubscriptionWebservices:CreateSubscriberAndTransaction:updating paymentSchedule');
                SubscriptionsWebservicesHandlers.updatePaymentSchedulesOnAccount(TSNumber, 'ONLINE', subscriptionDetails, null);
                System.debug('TMGLOG::SubscriptionWebservices:CreateSubscriberAndTransaction:updated paymentSchedule');
            }

            if(SAM_RESYNC_ENABLED && !lstAccs.isEmpty()){
                UpdateSamUserDetailsBatch.callSamForUpdateAsync(new Set<Id>{lstAccs[0].Id}, true, false);
            }

            result = new CreateSubscriberAndTransactionResult(TSNumber);

        } catch (WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new CreateSubscriberAndTransactionResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        } catch (Exception e){
            Database.rollback(sp);
            result = new CreateSubscriberAndTransactionResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('SubscriptionsWebservices.CreateSubscriberAndTransaction', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Create a new transaction history entry SMS-526 */
    webservice static GeneralSubscriptionsWebserviceResult CreateTransaction(String TSNumber, Payment paymentDetails, DirectDebitInfo directDebitDetails){
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'CreateTransaction', new Map<String,Object>{'TSNumber' => TSNumber,'paymentDetails' => paymentDetails});
        SavePoint sp = Database.setSavePoint();

        try{

            SubscriptionsWebservicesHandlers.createTransaction(TSNumber, paymentDetails, directDebitDetails, false);
            result = new GeneralSubscriptionsWebserviceResult();

        } catch (WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('CreateTransaction', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function - Callback on successful payments done via salesforce.
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         16/09/2015  //added constants
    Wiktor Czykin       1.2         06/10/2015  //added new field to soqls
    Cristina Anghenie   1.3         25/11/2015  //avoid updatingSAMAccount when SamGuid from salesforce doenst match guid in salesforce
    Michal Szewczyk     1.4         10/05/2016  //fix for POC deletion
    Lynette Lim         1.5         23/09/2016  //fix SOQL query missing field Subscription_Duration_Picklist__c in CreateTransactionAndUpsertSAMAccountv2
    ****************************************************************************************/
    webservice static GeneralSubscriptionsWebserviceResult CreateTransactionAndUpsertSAMAccountv2(String TSNumber, String SAMGuid, String POC, String IncentiveId, Payment paymentDetails, DirectDebitInfo directDebitDetails,CustomParameter[] clientCustomParam){
        System.debug('---- ### Inside method name CreateTransactionAndUpsertSAMAccountv2');
        System.debug('---- ### TSNumber: ' + TSNumber);
        System.debug('---- ### PaymentDetails: ' + paymentDetails);
        System.debug('---- ### RecurringInfo: ' + paymentDetails.recurringDetails);
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        string samAccountGuid;
        SavePoint sp;
        ID logId;
        try{
            System.debug('### IN CreateTransactionAndUpsertSAMAccount');
            // We get the Account information (Including RecordTypeId to know if it is a Digital or a Premium Account)
            Account acc = [SELECT Id, RecordTypeId, GUID__c, Salutation, FirstName, LastName, PersonEmail, PersonMailingStreet, PersonMailingCity,
                                   PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Digital_Product_Type__c,
                                   PersonHomePhone, Origin__c, Email_Sent__c,  TMG_Promo_Email__c,  TMG_Promo_Phone__c,
                                   TMG_Promo_Post__c, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Loyalty_SMS__c, POC__c,
                                   TMG_Partner_Promo_Email__c, Subscriber_Number_static__c, Subscriber_Digital_Status__c
                          From Account WHERE Subscriber_Number_Static__c=:TsNumber];

           // We determine the productType from the recordtype
           String productType = (acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName())?Constants.PRODUCT_DIGITAL : Constants.PRODUCT_PREMIUM);
           Boolean isOneOffPayment = (TMGUTil.isDataValid(paymentDetails.productName) && paymentDetails.productName.toLowerCase().equals('oneoffpayment'));
           System.debug('### IS_ONE_OFF_PAYMENT: ' + isOneOffPayment);

           if(!isOneOffPayment){
                Map<String, String> samExemptExceptions = GetSAMExemptExceptions();
                // Update/Create SAM Account
                SAMUtil samUtil = new SAMUtil();

                // update samAccount if there account has already a guid
                if(String.isNotBlank(acc.Guid__c)){
                    try{
                        samAccountGuid = acc.Guid__c;
                        samUtil.updateSamAccount(acc, TSNumber, samAccountGuid, productType, false);
                    }catch (WebserviceUtil.SamException e){
                        String samMessage = e.getError().errorMessage.replace('SAM Exception: ', '').trim();
                        SubscriptionsWebservicesHandlers.sendErrorEmail('CreateTransactionAndUpsertSAMAccount', 'No log', e.getMessage(), e);

                        if(!samExemptExceptions.containsKey(samMessage)){
                            result = new GeneralSubscriptionsWebserviceResult(e.getError());
                            return result;
                        }
                    }
                }else{
                    // create SAM account of there is no guid but there is an email address
                    if(String.isNotBlank(acc.PersonEmail)){
                        // Create SAM Account
                        // No logs as we do logs after
                        try{
                            samAccountGuid = samUtil.createSamAccount(acc, TSNumber, productType, false, true);
                        }catch (WebserviceUtil.SamException e){
                            String samMessage = e.getError().errorMessage.replace('SAM Exception: ', '').trim();
                            SubscriptionsWebservicesHandlers.sendErrorEmail('CreateTransactionAndUpsertSAMAccount', 'No log', e.getMessage(), e);

                            if(!samExemptExceptions.containsKey(samMessage)){
                                result = new GeneralSubscriptionsWebserviceResult(e.getError());
                                return result;
                            }
                        }
                    }

                    // Update MPP with GUID
                    try{
                        MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
                        mpp.UserManage(TSNumber, null, null, null, null, null, null, null, null, null, null, null, null, samAccountGuid);
                    }catch (MPPInterfaceHTTP.MPPInterfaceHTTPException e){
                        logId = TMGUtil.logWebServiceRequest('Outbound', null, 'samUtil.updateSamAccount', new Map<String,Object>{'acc' => acc, 'TSNumber' => TSNumber, 'SAMGuid' => samAccountGuid});
                        TMGUtil.logWebServiceDetail(logId, string.valueOf(e));
                        SubscriptionsWebservicesHandlers.sendErrorEmail('CreateTransactionAndUpsertSAMAccount', logId, e.getMessage(), e);
                        result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getErrorCode(), e.getErrorMessage()));
                        return result;
                    }

                    if(String.isNotBlank(acc.PersonEmail)){
                        System.debug('### IN ACCOUNT WITH GUID: ' + samAccountGuid);
                        // Update Salesforce Account with GUID
                        acc.Guid__c = samAccountGuid;
                        update acc;

                        // Logging call
                        logId = TMGUtil.logWebServiceRequest('Outbound', 'SAM', 'createAccount', new Map<String,Object>{'Account' => acc, 'TSNumber' => TSNumber});
                        // Logging response
                        TMGUtil.logWebServiceResponse(logId, acc.Guid__c);
                    }
                }

                result = new GeneralSubscriptionsWebserviceResult();
                // We DONT Update Subscriber status to Active because it's done in MPP_Transaction_History__c trigger
                SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(TSNumber, paymentDetails.serviceId);

                // Delete POC
                if(String.isNotBlank(POC)){
                    SubscriptionsWebservicesHandlers.deletePOC(POC);
                } else {
                    if(String.isNotBlank(acc.POC__c)){
                        SubscriptionsWebservicesHandlers.deletePOC(acc.POC__c);
                    }
                }

                // We set the start of the DML Transaction
                sp = Database.setSavepoint();
                Boolean createTransaction = true;
                Subscription__c sub = null;
                Subscription__c offeredRenwalSub = null;

                if(productType == Constants.PRODUCT_PREMIUM){
                    String clientParamSubId = null;
                    if (clientCustomParam != null){
                        for(SubscriptionsWebservices.CustomParameter clientCustomPrm : clientCustomParam){
                            System.debug('Looping through clientCustomParams');
                            System.debug('Param Name: '+clientCustomPrm.name+'Param Value'+clientCustomPrm.value);
                            if (clientCustomPrm.name == 'SubscriptionId'){
                                clientParamSubId = clientCustomPrm.value;
                            }
                        }
                    }

                    if (clientParamSubId == null){
                        // Updating the Subscription to Pending
                        sub = [SELECT Id, MPP_Premium_Subscription_ID__c, MPP_CC_First_Payment_Amount__c, MPP_CC_Frequency__c,
                                                    MPP_CC_Next_Payment_Date__c, MPP_DD_First_Payment_Amount__c, MPP_DD_Frequency__c,
                                                    MPP_DD_Next_Payment_Date__c, isContinuous__c, Start_Date__c, End_Date__c, Subscription_Duration_Picklist__c,
                                                    Subscription_Status__c, Digital_VAT_Rate__c, Payment_Type__c, MPP_Irregular_Payment_Schedule__c
                                                    FROM Subscription__c where Subscriber__c=:acc.id ORDER BY LastModifiedDate DESC LIMIT 1];

                        sub.Payment_Details_Received__c = true;
                        if(sub.Subscription_Status__c != Constants.SSTATUS_ACTIVE){
                            if (sub.Subscription_Status__c != Constants.SSTATUS_OFFERED){
                                try{
                                    offeredRenwalSub = [SELECT Id, MPP_Premium_Subscription_ID__c, MPP_CC_First_Payment_Amount__c, MPP_CC_Frequency__c,
                                                            MPP_CC_Next_Payment_Date__c, MPP_DD_First_Payment_Amount__c, MPP_DD_Frequency__c,
                                                            MPP_DD_Next_Payment_Date__c, isContinuous__c, Start_Date__c, End_Date__c, Subscription_Duration_Picklist__c,
                                                            Subscription_Status__c, Digital_VAT_Rate__c, Payment_Type__c, MPP_Irregular_Payment_Schedule__c
                                                            FROM Subscription__c where Subscriber__c=:acc.id and Subscription_Status__c not in ('In Renewal','Active')
                                                            ORDER BY LastModifiedDate DESC LIMIT 1];
                                    if (offeredRenwalSub != null){
                                        sub = offeredRenwalSub;
                                    }
                                }catch(Exception e){
                                    System.debug('Exception Occured while querying subscription'+e.getMessage());
                                }
                            }
                            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
                        }
                    }else{
                        // Updating the Subscription to Pending
                        sub = [SELECT Id, MPP_Premium_Subscription_ID__c, MPP_CC_First_Payment_Amount__c, MPP_CC_Frequency__c,
                                                    MPP_CC_Next_Payment_Date__c, MPP_DD_First_Payment_Amount__c, MPP_DD_Frequency__c,
                                                    MPP_DD_Next_Payment_Date__c, isContinuous__c, Start_Date__c, End_Date__c, Subscription_Duration_Picklist__c,
                                                    Subscription_Status__c, Digital_VAT_Rate__c, Payment_Type__c, Subscription_Duration_Number__c, MPP_Irregular_Payment_Schedule__c
                                                    FROM Subscription__c where Id=:clientParamSubId ORDER BY LastModifiedDate DESC LIMIT 1];

                        sub.Payment_Details_Received__c = true;
                        if(sub.Subscription_Status__c != Constants.SSTATUS_ACTIVE){
                            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
                        }
                    }

                    update SubscriptionsWebservicesHandlers.setMPPSubscriptionFields(sub, paymentDetails.recurringDetails);
                    // NO Transaction History for Premium Continuous
                    if(sub.IsContinuous__c){
                        createTransaction = false;
                    }
                }

                if(paymentDetails.paymentType == Constants.MPP_PAYMENTMETHOD_DD){
                    directDebitDetails = (directDebitDetails != null ? directDebitDetails : new DirectDebitInfo());
                    //In case of digital subscribers, update the digital subscription id and order id in the txn history
                    if(!Constants.PRODUCT_PREMIUM.equalsIgnoreCase(productType)) {
                        SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber, directDebitDetails, paymentDetails);
                    } else { // do BAU
                        SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber, (TMGUtil.isDataValid(sub) ? sub.Id : null), directDebitDetails);
                    }
                }

                // NO Transaction History for Premium Continuous
                if(createTransaction){
                    // Create the transaction
                    /*
                    *   MPP_Transaction_History__c TRIGGER:
                    *   switch premium to active if it is pending cancel
                    *   switch premium to pending if it is offered
                    *   switch digital to active
                    */
                    SubscriptionsWebservicesHandlers.createTransaction(TSNumber, paymentDetails, directDebitDetails, true);
                }

                // Create Incentives associations
                SubscriptionsWebservicesHandlers.createSubscriberIncentive(TSNumber, (TMGUtil.isDataValid(sub) ? sub.Id : null), IncentiveId);

                // added condition to check if Subscription is IsContinous
                if(Constants.PRODUCT_PREMIUM == productType && sub.IsContinuous__c) {
                    SubscriptionsWebservicesHandlers.updatePaymentSchedulesOnAccount(TsNumber, 'OFFLINE', null, paymentDetails);
                }
            }else{
                if (clientCustomParam != null){
                    System.debug('Client Custom Params are not null'+clientCustomParam);
                    System.debug('Client Custom Params are not null');
                    SubscriptionsWebservicesHandlers.createTransaction(TSNumber, paymentDetails, directDebitDetails, true, clientCustomParam);
                }else{
                    System.debug('Client Custom Params are null');
                    SubscriptionsWebservicesHandlers.createTransaction(TSNumber, paymentDetails, directDebitDetails, true);
                }
           }
           result = new GeneralSubscriptionsWebserviceResult();
           logId = TMGUtil.logWebServiceRequest('Inbound', null, 'CreateTransactionAndUpsertSAMAccountv2', new Map<String,Object>{'TSNumber' => TSNumber, 'SAMGuid' => samAccountGuid, 'POC' => acc.Poc__c, 'IncentiveId' => IncentiveId, 'paymentDetails' => paymentDetails, 'directDebitDetails' => directDebitDetails});

        } catch (WebserviceUtil.WSException wse){
            if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            ex = wse;
        } catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('CreateTransactionAndUpsertSAMAccount', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/11/2015
    Version - 1.0
    Function - Fully replaced version - now based on map - removed looping
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Subscriber checkClientCustomParams(Subscriber subscriberDetails, Map<String, String> mapParams){
        if(mapParams != null && subscriberDetails != null){
            if(mapParams.containsKey('pricingoptionname') && String.isNotBlank(mapParams.get('pricingoptionname'))){
                List<Pricing_Options__c> lstPricingOptionInfo = [select Id, Name from Pricing_Options__c where Name = :mapParams.get('pricingoptionname')];
                if(!lstPricingOptionInfo.isEmpty()){
                    subscriberDetails.PricingOptionId = lstPricingOptionInfo[0].Id;
                }else{
                    TMGUtil.logWebServiceRequest('Inbound', null, 'checkClientCustomParams', new Map<String,Object>{'error when calculating PricingOptions for subscriberDetailValues' => subscriberDetails});
                }
            }
        }

        return subscriberDetails;
    }
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 22/03/2016
    Function - check mapParams and fetch Product information
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   27/05/2016  //modified default product key to constant
    Michal Szewczyk 02/06/2016  //fix for MPP Promo Code flow and digital entitlement
    Michal Szewczyk 20/07/2016  //fix for webpack and digital subscriberType
    Wiktor Czykin   06/07/2017  //fix for default product being assigned when should not be        
    ****************************************************************************************/
    public static zqu__ZProduct__c fetchProductAndSetClientProd(Subscriber subscriberDetails, Map<String, String> mapParams){
        List<zqu__ZProduct__c> lstProductInfo;
        if(mapParams != null && subscriberDetails != null && mapParams.containsKey('productId') && String.isNotBlank(mapParams.get('productId'))){
            lstProductInfo = [select Id, Name,Print_Product__c,ProductCountry__c,zqu__Active__c from zqu__ZProduct__c where Id = :mapParams.get('productId')];
            if(!lstProductInfo.isEmpty()){
                subscriberDetails.productId = lstProductInfo[0].Id;
                subscriberDetails.isPrint = lstProductInfo[0].Print_Product__c;
                return lstProductInfo[0];
            }else{
                TMGUtil.logWebServiceRequest('Inbound', null, 'fetchProductAndSetClientProd', new Map<String,Object>{'error when setting Product for subscriberDetailValues' => subscriberDetails});
            }
        }else if(subscriberDetails != null && String.isNotBlank(subscriberDetails.subscriberType)) {
            General__c defaultProduct ;
            if(subscriberDetails.subscriberType == Constants.PRICING_DIGITAL_TYPE) {
                defaultProduct = General__c.getValues(Constants.DIGITAL_DEFAULT_PRODUCT_ID);
            } else if(subscriberDetails.subscriberType == Constants.PRICING_WEBPACK_TYPE) {
                defaultProduct = General__c.getValues(Constants.WEBPACK_DEFAULT_PRODUCT_ID);
            }else if(subscriberDetails.subscriberType == Constants.PRICING_PREMIUM_TYPE){
                defaultProduct = General__c.getValues(Constants.GENERAL_DEFAULT_PRODUCT_ID);
            }

            if(defaultProduct != null && String.isNotBlank(defaultProduct.Value__c)) {
                 lstProductInfo = [select Id, Name,Print_Product__c,ProductCountry__c,zqu__Active__c from zqu__ZProduct__c where Id = :defaultProduct.Value__c];
            }
            if(!lstProductInfo.isEmpty()){
                subscriberDetails.productId = lstProductInfo[0].Id;
                subscriberDetails.isPrint = lstProductInfo[0].Print_Product__c;
                return lstProductInfo[0];
            }else{
                TMGUtil.logWebServiceRequest('Inbound', null, 'fetchProductAndSetClientProd', new Map<String,Object>{'error when setting Product for subscriberDetailValues' => subscriberDetails});
            }
        }

        return null;
    }
    /***************************************************************************************
    * @author Wiktor Czykin
    * @date 30/11/2015
    * @description simple method to map list of params into a map
    #############Change Log#############
    Modified by         Version     Change Date
    ***************************************************************************************/
    public static Map<String, String> remapClientCustomParams(List<CustomParameter> lstParams){
        Map<String, String> mapKeyValue = new Map<String, String>();
        if(lstParams != null){
            for(CustomParameter cp : lstParams){
                if(String.isNotBlank(cp.name)){
                    mapKeyValue.put(cp.name, cp.value);
                }
            }
        }
        return mapKeyValue;
    }

    //Check Digital subscriber's account status
    webservice static CheckDigitalSubscriberStatusResult CheckDigitalSubscriberStatus(String TSNumber){
        Exception ex;
        CheckDigitalSubscriberStatusResult result;
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'CheckDigitalSubscriberStatus', new Map<String,Object>{'TSNumber' => TSNumber});

        try{
            String status = SubscriptionsWebservicesHandlers.checkDigitalSubscriberStatus(TSNumber);
            result = new CheckDigitalSubscriberStatusResult(status);
        } catch (WebserviceUtil.WSException wse){
            result = new CheckDigitalSubscriberStatusResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        } catch (Exception e){
            result = new CheckDigitalSubscriberStatusResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('CheckDigitalSubscriberStatus', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.4
    Function - Main method that generates sale offer for online flows based on campaign and pricing information
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //added handling of null tCodeObj var, updated getIncentives() call signature
    Michal Szewczyk 1.2         04/04/2016  //productType become productId and we set it as default for premium product until we implement product unbundling
    Lynette Lim     1.3         28/04/2016  //Set default ProductID for online POC flow to work with Product Unbundling until AEM replacement for online flows
    Wiktor Czykin   1.4         27/05/2016  //Modified the custom setting to use common General__c default product id
    ****************************************************************************************/
    webservice static GetTCodeAndIncentivesResult GetTCodeAndIncentives(String productType, String flowType, String tCode, String SubscriptionType, String POC, String packagename){
        Exception ex;
        GetTCodeAndIncentivesResult result;
        Id logId = TMGUtil.logWebServiceRequest('Inbound', null, 'GetTCodeAndIncentives', new Map<String,Object>{'productType' => productType, 'flowType' => flowType, 'tCode' => tCode, 'SubscriptionType' => SubscriptionType, 'POC' => POC});
        Id productId;
        try{
            if(!Test.isRunningTest()){
                try{
                    productId = (Id) productType;
                }catch(Exception e){}
                if(productId == null){
                General__c defaultProduct = General__c.getValues(Constants.GENERAL_DEFAULT_PRODUCT_ID);
                if(defaultProduct != null && String.isNotBlank(defaultProduct.Value__c) && !(productType == 'digital' || productType == 'webpack')) productType = defaultProduct.Value__c;
            }
            }
            // modified as part of Vodafone to use the getTCode class, which has now been modified to return values in the TCode object format
            Tcode tCodeObj = SubscriptionsWebservicesHandlers.getTCodeNewImpl(POC, flowType, tCode);

            if(tCodeObj == null){
                throw new WebserviceUtil.NullParameterException('TCode', '');
            }
            // ensure that the tCode identified from the above class is used for the remainder of this class.
            tCode = tCodeObj.tCode;
            List<Incentive> lstIncentives = SubscriptionsWebservicesHandlers.getIncentives(productType, tCodeObj, subscriptionType);

            // retrieve relevant pricing option info for current Tcode
            Pricing_Options__c pricingOptions;
            pricingOptions = GlobalQueries.getPricingOptions(productType, flowType, subscriptionType, tCode);
            if(pricingOptions==null){
                throw new WebserviceUtil.GenericWSException('NOPRICINGOPTION','No Pricing option found for input parameters');
            }

            PricingOption pricingOption= new PricingOption(pricingOptions.ServiceId__c);
            pricingOption.servicePriceId = pricingOptions.ServicePriceId__c;
            pricingOption.dynamicPrice = pricingOptions.Dynamic_Price__c;
            pricingOption.flowType = pricingOptions.Flow_Type__c;
            pricingOption.subscriptionType = pricingOptions.Subscription_Type__c;
            pricingOption.discountVoucher = pricingOptions.Multi_User_Discount_Voucher__c;
            pricingOption.paymentRequired = pricingOptions.Payment_Required__c;
            pricingOption.PackageName = pricingOptions.Package_Name__c;
            pricingOption.pricingoptionsname = pricingOptions.name;
            tCodeObj.imageURL = pricingOptions.imageURL__c;
            tCodeObj.tCodeRecord = null;
            result = new GetTCodeAndIncentivesResult(tCodeObj,pricingOption, lstIncentives);

        }catch (WebserviceUtil.WSException wse){
            result = new GetTCodeAndIncentivesResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }catch (Exception e){
            result = new GetTCodeAndIncentivesResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('GetTCodeAndIncentives', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Added New method as a part of Vodafone???
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //added handling of null tCodeObj var, changed call to getTCodeDetails(), changed getIncentives() method signature
    Michal Szewczyk 1.2         04/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    webservice static GetTCodeAndIncentivesResult GetTcodeIncentivesByPromoName(String ServiceID, String ServicePriceID, String PromoName){
        Exception ex;
        GetTCodeAndIncentivesResult result;
        //define webservice log for GetTcodeIncentivesByPromoName API
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'GetTcodeIncentivesByPromoName', new Map<String,Object>{'ServiceID' => ServiceID, 'ServicePriceID' => ServicePriceID, 'PromoName' => PromoName});
        try{
            // retrieve relevant pricing option info for current ServiceID, ServicePriceID and PromoName
            Pricing_Options__c pricingOptions = SubscriptionsWebservicesHandlers.getPricingOptionsByServiceIDs(ServiceID, ServicePriceId, PromoName);

            // return error if pricingOptions is null
            if(pricingOptions == null)
               throw new WebserviceUtil.GenericWSException('NOPRICINGOPTION','No Pricing option found for input parameters');

            // populate pricingOption object with results from above
            PricingOption pricingOption= new PricingOption(pricingOptions.ServiceId__c);
            pricingOption.servicePriceId = pricingOptions.ServicePriceId__c;
            pricingOption.dynamicPrice = pricingOptions.Dynamic_Price__c;
            pricingOption.flowType = pricingOptions.Flow_Type__c;
            pricingOption.subscriptionType = pricingOptions.Subscription_Type__c;
            pricingOption.discountVoucher = pricingOptions.Multi_User_Discount_Voucher__c;
            pricingOption.paymentRequired = pricingOptions.Payment_Required__c;
            pricingOption.PackageName = pricingOptions.Package_Name__c;
            pricingOption.pricingoptionsname = pricingOptions.name;

            // ensure that the tCode identified from the above class is used for the remainder of this class.
            String tCode = pricingOptions.TCodeManagement__r.Name;

            // This method is returning TCode object
            Tcode tCodeObj = SubscriptionsWebservicesHandlers.getTCodeDetails(new Set<String>{'Name = \''+String.escapeSingleQuotes(tcode)+'\''});
            if(tCodeObj == null){
                throw new WebserviceUtil.NullParameterException('TCode', '');
            }

            // The below values are being returned as part of the tCode object, but sourced from PricingOptions so that the First Clarity WSDL does not need to be changed during EUK delivery.
            tCodeObj.showCancelButton = pricingOptions.Show_Cancel_Button__c;
            tCodeObj.displayExpiryDate = pricingOptions.Display_Expiry_Date__c;
            tCodeObj.imageURL = pricingOptions.imageURL__c;
            tCodeObj.tandcURL = pricingOptions.tandcURL__c;
            List<Incentive> incentives = SubscriptionsWebservicesHandlers.getIncentives(pricingOptions.TCode_Product__r.Product__c, tCodeObj, pricingOptions.Subscription_Type__c);
            tCodeObj.tCodeRecord = null;
            result = new GetTCodeAndIncentivesResult(tCodeObj, pricingOption, incentives);
        } catch (WebserviceUtil.WSException wse){
            result = new GetTCodeAndIncentivesResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        } catch (Exception e){
            result = new GetTcodeAndIncentivesResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    webservice static RenewalOffer GetRenewalOffer(string tsNumber,string postcode){
        RenewalOffer result;
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'GetRenewalOffer', new Map<String,Object>{'TSNumber' => tsNumber});
        result = SubscriptionsWebservicesHandlers.getRenewalOffer(tsNumber);
        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Check that the given TCode and postcode exist in the system and are valid*/
    webservice static ValidatePOCResult ValidatePOC(String POC, String postCode){
        Exception ex;
        ValidatePOCResult result;
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'ValidatePOC', new Map<String,Object>{'POC' => POC, 'PostCode' => PostCode});
        POCDetails details = SubscriptionsWebservicesHandlers.getPOCStatus(POC, PostCode);
        result = new ValidatePOCResult(details.POCStatus, details.TCode, details.prices);

        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('ValidatePOC', logId, result.wsError.errorMessage, ex);
        }
        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Update the date/time a user accessed a particular digital device*/
    webservice static GeneralSubscriptionsWebserviceResult UpdateLastAccessedData(String TSNumber, String device, Datetime lastAccessed){

        Exception ex;
        GeneralSubscriptionsWebserviceResult result = new GeneralSubscriptionsWebserviceResult();
        ID logId;

        logId = TMGUtil.logWebServiceRequest('Inbound', null, 'UpdateLastAccessedData', new Map<String,Object>{'TSNumber' => TSNumber, 'device' => device, 'lastAccessed' => lastAccessed});
        Savepoint sp = Database.setSavePoint();

        try{
            SubscriptionsWebservicesHandlers.updateLastAccessedData(TSNumber, device, lastAccessed);

        } catch (WebserviceUtil.WSException wse){
            database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('UpdateLastAccessedData', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Called to indicate the DD setup process has failed for a subscriber*/
    webservice static GeneralSubscriptionsWebserviceResult DDSetupFailure(String TSNumber, String FailureReason, String failureCode){

        Exception ex;
        GeneralSubscriptionsWebserviceResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DDSetupFailure', new Map<String,Object>{'TSNumber' => TSNumber, 'FailureReason' => FailureReason});
        Savepoint sp = Database.setSavePoint();

        try{
            SubscriptionsWebservicesHandlers.DDSetupFailure(TSNumber, FailureReason, failureCode);
            result = new GeneralSubscriptionsWebserviceResult();

        } catch (WebserviceUtil.WSException wse){
            database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('DDSetupFailure', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;

    }

    /*** New method added for PP-1702 Changes * DDSetupFailureOverLoad method with different signature to pass Subscriber and Payment as Argument*/
    webservice static GeneralSubscriptionsWebserviceResult DDSetupFailureOverLoad(Subscriber Subscriberdetails, String FailureReason, String failureCode,Payment Paymentdetails){

        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
       //Changes Made to Retrieve TSNumber from Subscriberdetails
        String TSNumber;
        if(Subscriberdetails !=null){
            TSNumber=Subscriberdetails.TSNumber;

        }

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DDSetupFailure', new Map<String,Object>{'TSNumber' => TSNumber, 'FailureReason' => FailureReason});
        Savepoint sp = Database.setSavePoint();

        try{
            //Pass PaymentDetail as Parameter#pp-1702
            SubscriptionsWebservicesHandlers.DDSetupFailure(Subscriberdetails, FailureReason, failureCode,Paymentdetails);
            result = new GeneralSubscriptionsWebserviceResult();

        } catch (WebserviceUtil.WSException wse){
            database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }

        catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('DDSetupFailure', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;

    }

     /**
     * New method added for PP-1702 Changes
     * Called when the collection of a DD payment fails
     * FailedPaymentOverLoad method with different signature to pass Subscriber Insted of 'TSNumber'
     */
    webservice static GeneralSubscriptionsWebserviceResult FailedPaymentOverLoad(Subscriber Subscriberdetails, Payment PaymentDetails, String TransactionCode, String FailureReason){

        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        //@cognizant=> Changes Made to Retrieve TSNumber from Subscriberdetails
        String TSNumber;
        if(Subscriberdetails.TSNumber!=null){
            TSNumber=Subscriberdetails.TSNumber;

        }

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'FailedPayment', new Map<String,Object>{'TSNumber' => TSNumber,'PaymentDetails' => PaymentDetails, 'TransactionCode' => TransactionCode, 'FailureReason' => FailureReason});

        try{
            //@cognizant : Instead of 'TsNumber' Currently we are passing Subscriberdetails  as Argument in Handler class
            SubscriptionsWebservicesHandlers.paymentFailure(Subscriberdetails, PaymentDetails, FailureReason, TransactionCode);
            result = new GeneralSubscriptionsWebserviceResult();

        } catch (WebserviceUtil.WSException wse){
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('FailedPayment', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Called when the collection of a DD payment fails
    */
    webservice static GeneralSubscriptionsWebserviceResult FailedPayment(String TSNumber, Payment PaymentDetails, String TransactionCode, String FailureReason){

        Exception ex;
        GeneralSubscriptionsWebserviceResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'FailedPayment', new Map<String,Object>{'TSNumber' => TSNumber,'PaymentDetails' => PaymentDetails, 'TransactionCode' => TransactionCode, 'FailureReason' => FailureReason});

        try{
            SubscriptionsWebservicesHandlers.paymentFailure(TSNumber, PaymentDetails, FailureReason, TransactionCode);
            result = new GeneralSubscriptionsWebserviceResult();

        } catch (WebserviceUtil.WSException wse){
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('FailedPayment', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }


     webservice static GeneralSubscriptionsWebserviceResult DigitalSubscriptionEnded(String TSNumber){
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'DigitalSubscriptionEnded', new Map<String,Object>{'TSNumber' => TSNumber});

        try{
            SubscriptionsWebservicesHandlers.digitalSubscriptionEnded(TSNumber);
            result = new GeneralSubscriptionsWebserviceResult();

        } catch (WebserviceUtil.WSException wse){
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('DigitalSubscriptionEnded', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Get the details of an active subscription to display to a user*/
    webservice static GetActiveSubscriptionDetailsResult GetActiveSubscriptionDetails(String TSNumber){
        Exception ex;
        GetActiveSubscriptionDetailsResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'GetActiveSubscriptionDetails', new Map<String,Object>{'TSNumber' => TSNumber});

        try{
            ActiveSubscription sub = SubscriptionsWebservicesHandlers.getActiveSubscriptionDetails(TSNumber);
            result = new GetActiveSubscriptionDetailsResult(sub);

        } catch (WebserviceUtil.WSException wse){
            result = new GetActiveSubscriptionDetailsResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            result = new GetActiveSubscriptionDetailsResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('GetActiveSubscriptionDetails', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Get the details of an active subscription to display to a user
    */
    //MIRFAN@Appirio 13Feb12
    webservice static SubscriptionsWebservices.ActiveAndRenewedSubscriptionResult GetActiveAndRenewedSubscriptionDetails(String TSNumber, String Postcode){
        Exception ex;
        ActiveAndRenewedSubscriptionResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'getActiveAndRenewedSubscriptionDetails', new Map<String,Object>{'TSNumber' => TSNumber});

        try{
            result = SubscriptionsWebservicesHandlers.getActiveAndRenewedSubscriptionDetails(TSNumber,Postcode);
        } catch (WebserviceUtil.WSException wse){
            result = new ActiveAndRenewedSubscriptionResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            result = new ActiveAndRenewedSubscriptionResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('getActiveAndRenewedSubscriptionDetails', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /** Get the details of an lapsed subscription to display to a user
    */
    webservice static GetLapsedSubscriptionDetailsResult GetLapsedSubscriptionDetails(String TSNumber){
        Exception ex;
        GetLapsedSubscriptionDetailsResult result;

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'GetLapsedSubscriptionDetails', new Map<String,Object>{'TSNumber' => TSNumber});

        try{
            LapsedSubscription sub = SubscriptionsWebservicesHandlers.getLapsedSubscriptionDetails(TSNumber);
            result = new GetLapsedSubscriptionDetailsResult(sub);

        } catch (WebserviceUtil.WSException wse){
            result = new GetLapsedSubscriptionDetailsResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
            result = new GetLapsedSubscriptionDetailsResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('GetLapsedSubscriptionDetails', logId, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(logId, result);
        return result;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Not quite sure on what callout this callback is executed
    #############Change Log#############
    Wiktor Czykin   1.1         02/06/2015  //changed variables to constants, changed updateFailedUserManageRequests() call as method signature was changed
    ****************************************************************************************/
    WebService static GeneralSubscriptionsWebserviceResult processFailedMPPUserManageRequests(List<FailedUserManageResult> tasks){
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        //Lets store a log of the result here first.
        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_INBOUND,
                                                                        null,
                                                                        Constants.LOG_USERMANAGE_CALLBACK_FAILURES,
                                                                        new Map<String, Object>{'List<FailedUserManageResult>' => String.valueOf(tasks)});
        SavePoint sp = Database.setSavepoint();


        try{
            SubscriptionsWebservicesHandlers.updateFailedUserManageRequests(wl.Id, 'MPP', tasks);
            // PP-1693 - empty result should be returned in case of success
            result = new GeneralSubscriptionsWebserviceResult();
        }catch(WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(wl.Id, String.valueOf(wse));
            ex = wse;
        }catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(wl.Id, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail(Constants.LOG_USERMANAGE_CALLBACK_FAILURES, wl.Id, result.wsError.errorMessage, ex);
        }

        return result;
    }


    public static Map<String, String> GetSAMExemptExceptions()
    {
        Map<String, String> exceptionMap = new Map<String, String>();
        try{
            for(String value :System.Label.SAM_EXEMPT_EXCEPTIONS.split(',')){
                exceptionMap.put(value.trim(), value.trim());
            }
        }catch(System.Exception e){
            System.debug('#### Error in GetSAMExemptExceptions: ' + e.getMessage());
        }
        return exceptionMap;
    }

    //MIrfan@Appirio, Plane 1.2, BulkDDSetupFailure handling from MPP, 110512
    WebService static GeneralSubscriptionsWebserviceResult processFailedMPPDirectDebitRequests(List<FailedMPPBulkResult> lstFailedTSNumbers)
    {
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        //Lets store a log of the result here first.
        Id logId = TMGUtil.logWebServiceRequest('Inbound', null, 'processFailedMPPDirectDebitRequests', new Map<String, Object>{'List<FailedMPPBulkResult>' => String.valueOf(lstFailedTSNumbers)});
        SavePoint sp = Database.setSavepoint();

        try{
            SubscriptionsWebservicesHandlers.updateFailedDirectDebitRequests('MPP', lstFailedTSNumbers);
            // PP-1693 - empty result should be returned in case of success
            result = new GeneralSubscriptionsWebserviceResult();
        }catch(WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(logId, String.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(logId, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail('processFailedMPPDirectDebitRequests', logId, result.wsError.errorMessage, ex);
        }

        return result;
    }

    /***************************************************************************************
    Developer - MIrfan@Appirio
    Date - Unknown
    Version - 1.2
    Function -  BulkPaymentScheduleFailure handling from MPP, 110512
    #############Change Log#############
    Wiktor Czykin   1.1         02/06/2015  //changed variables to constants, changed updateFailedPaymentScheduleRequests() version being called
    Wiktor Czykin   1.2         02/07/2015  //removed the String.valueOf() from method call
    ****************************************************************************************/
    WebService static GeneralSubscriptionsWebserviceResult processFailedMPPPaymentScheduleRequests(List<FailedMPPBulkResult> lstFailedTSNumbers){
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        //Lets store a log of the result here first.
        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_INBOUND,
                                                                        null,
                                                                        Constants.LOG_PAYMENTSCHEDULE_CALLBACK_FAILURES,
                                                                        new Map<String, Object>{'List<FailedMPPBulkResult>' => lstFailedTSNumbers});
        SavePoint sp = Database.setSavepoint();

        try{
            SubscriptionsWebservicesHandlers.updateFailedPaymentScheduleRequests(wl.Id, 'MPP', lstFailedTSNumbers);
            // PP-1693 - empty result should be returned in case of success
            result = new GeneralSubscriptionsWebserviceResult();
        }catch(WebserviceUtil.WSException wse){
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(wl.Id, String.valueOf(wse));
            ex = wse;
        }
        catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
                Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(wl.Id, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }
        if(result != null && result.wsError != null){
            SubscriptionsWebservicesHandlers.sendErrorEmail(Constants.LOG_PAYMENTSCHEDULE_CALLBACK_FAILURES, wl.Id, result.wsError.errorMessage, ex);
        }

        return result;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function -  This method will be called from MPP for updates to be made on Account and Subscription objects
                @param  listPaymentSchedules     list of SubscriptionsWebservices.PaymentSchedules class containing the records to be processed
                @return result                   the GeneralSubscriptionsWebserviceResult object as part of result being returned to the caller
    #############Change Log#############
    Wiktor Czykin   1.1         02/06/2015  //changed variables to constants
    Wiktor Czykin   1.2         02/07/2015  //removed the String.valueOf() from method call
    ****************************************************************************************/
    WebService static GeneralSubscriptionsWebserviceResult processPaymentScheduleSetupSuccess(List<PaymentSchedules> listPaymentSchedules) {
        Exception ex;
        GeneralSubscriptionsWebserviceResult result;
        WebService_Log__c wl = TMGUtil.logWebServiceRequestSerialized(  Constants.DIRECTION_INBOUND,
                                                                        null,
                                                                        Constants.LOG_PAYMENTSCHEDULE_CALLBACK,
                                                                        new Map<String, Object> {'List<PaymentSchedules>' => listPaymentSchedules});

        SavePoint sp = Database.setSavepoint();
        try {
            SubscriptionsWebservicesHandlers.updateSuccessPaymentScheduleSetup(wl.Id, listPaymentSchedules);
            result = new GeneralSubscriptionsWebserviceResult();
        } catch (WebserviceUtil.WSException wse) {
            Database.rollback(sp);
            result = new GeneralSubscriptionsWebserviceResult(wse.getError());
            TMGUtil.logWebServiceDetail(wl.Id, String.valueOf(wse));
            ex = wse;
        } catch (Exception e){
             if(TMGUtil.isDataValid(sp)){
            Database.rollback(sp);
            }
            result = new GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSError(e.getMessage(),'stackTrace: '+e.getStackTraceString()));
            TMGUtil.logWebServiceDetail(wl.Id, e.getMessage()+'stackTrace: '+e.getStackTraceString());
            ex = e;
        }

        if(result != null && result.wsError != null) {
            SubscriptionsWebservicesHandlers.sendErrorEmail(Constants.LOG_PAYMENTSCHEDULE_CALLBACK, wl.Id, result.wsError.errorMessage, ex);
        }

        TMGUtil.logWebServiceResponse(wl.Id, result);
        return result;
    }

   //PP-1702 Changes@Cognizant
    //MIrfan@Appirio, Plane 1.2, BulkPaymentScheduleFailure handling from MPP, 110512
    global class FailedMPPBulkResult
    {
        WebService String tsNumber;
        WebService String subject;
        WebService String message;
        WebService String status;

       // public WebService String premiumSubID;
    }

    global class FailedUserManageResult
    {
        public WebService String tsNumber;
        public WebService String subject;
        public WebService String message;
        public WebService String status;
        public WebService String firstName;
        public WebService String lastName;
        public WebService String emailAddress;
    }

     global class CustomParameter {
        webservice String name;
        webservice String value;
    }


     //Added as a part of vodafone
    global class Subscriber{
        webservice String subscriberType;
        webservice String digitalSubscriberStatus;
        webservice String title;
        webservice String firstName;
        webservice String lastName;
        webservice String personalEmail;
        webservice String street;
        webservice String city;
        webservice String postalCode;
        webservice String country;
        webservice String county;
        webservice String homePhone;
        webservice String mobilePhone;
        webservice Boolean marketingEmailPref;
        webservice Boolean marketingPhonePref;
        webservice Boolean marketingPostPref;
        webservice Boolean marketingSMSPref;
        webservice String TSNumber;
        webservice String GUID;
        webservice String TCode;
        webservice String poc;

        /*Added as a part of VOD-15*/
        webservice DealWebservice.Token token;

        // DM 30/04 - this value is not being passed in from 3rd Parties at present. Instead it will be used to carry the PricingOptionName (passed in via CustomClientParams) to the create/update subscriber calls. This is to minimise code complexity so close to Hygiene
        webservice String PricingOptionID ;

        // Added for population Product__c
        webservice String productId;
        webservice Boolean isPrint;
    }

    global class Payment{
        webservice DateTime paymentDate;
        webservice Decimal amountGross;
        webservice String currencyType;
        webservice String paymentStatus;
        webservice String paymentType;
        webservice String productName;
        webservice String digitalSubscriptionID;
        webservice String orderId;
        webservice String serviceId;
        webservice String cardType;
        Webservice MPPRecurringInfo recurringDetails;

    }

    global class DirectDebitInfo{
        webservice String accountName;
        webservice String accountNumber;
        webservice String sortCode;
        //MIrfan@Appirio - 240412. exposed below audit fields.
        webservice String auddisRef;
        webservice Date submittedPaymentDate;
    }

    global class MPPRecurringInfo{
        Webservice String paymentType;
        WebService String premiumSubscriptionID;
        Webservice Decimal firstPaymentAmount;
        Webservice String frequency;
        WebService Date nextPaymentDate;
    }

    global class Subscription{
        webservice String productType;
        webservice String paymentType;
        webservice String subscriptionType;
        webservice Date startDate;
        webservice Date paymentDate;
        webservice string promoCode;
        webservice string promoName;
        webservice date promoValidToDate;
    }

    public class POCDetails{
        public String POCStatus;
        public String TCode;
        public List<SubPrice> prices;
    }

    global class SubPrice{
        webservice String productType;
        webservice String subscriptionType;
        webservice Decimal price;
        webservice List<Incentive> incentives;
    }

    global class Incentive{
        webservice String Id;
        webservice String ImageUrl;
        webservice String Description;
    }

    global class LastAccessedDetails{
        webservice String TSNumber;
        webservice String Device;
        webservice DateTime LastAccessed;
    }

    global class ActiveSubscription{
        webservice String TSNumber;
        webservice String SubscriptionType;
        webservice Date ExpiryDate;
        webservice Decimal WeeklyPrice;
        webservice Date NextVoucherPack;
        webservice String PaymentType;
        webservice Decimal LastPaymentAmount;
        webservice Date LastPaymentDate;
        webservice boolean IsMPP;
    }

    //MIRFAN@Appirio 13Feb12
    global class ActiveAndRenewedSubscription {
        webservice Date StartDate;
        webservice String TSNumber;
        webservice String SubscriptionType;
        webservice Date ExpiryDate;
        webservice Decimal WeeklyPrice;
        webservice Date NextVoucherPack;
        webservice String PaymentType;
        webservice Decimal LastPaymentAmount;
        webservice Date LastPaymentDate;
        webservice boolean IsMPP;
        webservice String Status;
    }

    //MIRFAN@Appirio 13Feb12
    global class ActiveAndRenewedSubscriptionResult{
        webservice List<ActiveAndRenewedSubscription> Subscriptions;
        webservice WebserviceUtil.WSError wsError;
        public ActiveAndRenewedSubscriptionResult()
        {
            Subscriptions = new  List<ActiveAndRenewedSubscription>();
        }

        public ActiveAndRenewedSubscriptionResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    global class LapsedSubscription{
        webservice String TSNumber;
        webservice String SubscriptionType;
        webservice Date Expired;
        webservice Boolean IsRenewable;
    }

    /** A class to encapsulate the general response from the webservice
        This response is used for most of the calls
    */
    global class GeneralSubscriptionsWebserviceResult{
        webservice WebserviceUtil.WSError wsError;

        public GeneralSubscriptionsWebserviceResult(){
        }

        public GeneralSubscriptionsWebserviceResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    /** A class to encapsulate the response from the CreateDigitalSubscriberAndTransaction webservice method
        This contains more specific information - would ideally be composed using inhertiance but
        SF makes this impossible - see tech doc for more details
    */
    global class CreateSubscriberAndTransactionResult{
        webservice String TSNumber;
        webservice WebserviceUtil.WSError wsError;

        public CreateSubscriberAndTransactionResult(String TSNumber){
            this.TSNumber = TSNumber;
        }

        public CreateSubscriberAndTransactionResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    global class CreateSubscriberResult{
        webservice String TSNumber;
        webservice WebserviceUtil.WSError wsError;

        public CreateSubscriberResult(String TSNumber){
            this.TSNumber = TSNumber;
        }

        public CreateSubscriberResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    global class CheckDigitalSubscriberStatusResult{
        webservice String digitalSubscriberStatus;
        webservice WebserviceUtil.WSError wsError;

        public CheckDigitalSubscriberStatusResult(String digitalSubscriberStatus){
            this.digitalSubscriberStatus = digitalSubscriberStatus;
        }

        public CheckDigitalSubscriberStatusResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    /**
    * @author Unknown
    * @date Unknown
    * @description
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //added transient var to store the fetched record, removed not used constructor
    **/
    global class Tcode{
        public transient TCodeManagement__c tCodeRecord;
        webservice String tCode;
        webservice String promoName;
        webservice String promoType;
        webservice String partnerName;
        webservice String partnerCCenterEmail;
        webservice String partnerCCenterNumber;
        webservice String imageURL;
        webservice String tAndCURL;
        webservice Boolean showCancelButton;
        webservice Boolean displayExpiryDate;
        webservice Integer gpStageOneDuration;
        webservice Integer gpStageTwoDuration;

        public Tcode(String tCode){
            this.tCode = tCode;
        }
    }

    global class PricingOption{
        webservice Decimal serviceId;
        webservice Decimal servicePriceId;
        webservice Decimal dynamicPrice;
        webservice String flowType;
        webservice String subscriptionType;
        webservice String discountVoucher;
        webservice Boolean paymentRequired;
        webservice String packagename;
        webservice String pricingoptionsname;

        public PricingOption(Decimal serviceId,Decimal servicePriceId,Decimal dynamicPrice,String flowType,String subscriptionType,String discountVoucher,Boolean paymentRequired,String packagename,String pricingoptionsname){
            this.serviceId = serviceId;
            this.servicePriceId = servicePriceId;
            this.dynamicPrice = dynamicPrice;
            this.flowType = flowType;
            this.subscriptionType = subscriptionType;
            this.discountVoucher = discountVoucher;
            this.paymentRequired = paymentRequired;
            this.packagename=packagename;
            this.pricingoptionsname=pricingoptionsname;
        }

       public PricingOption(Decimal serviceId){
            this.serviceId = serviceId;
        }

   }

    //Added change for Vodafone
    global class GetTCodeAndIncentivesResult{
        webservice Tcode tCode;
        webservice PricingOption pricingOption;
        webservice List<SubscriptionsWebservices.Incentive> incentives;
        webservice WebserviceUtil.WSError wsError;

        public GetTCodeAndIncentivesResult(Tcode tCode, PricingOption pricingOption,List<SubscriptionsWebservices.Incentive> incentives){
            this.tCode = tCode;
            this.pricingOption=pricingOption;
            this.incentives = incentives;
        }

        public GetTCodeAndIncentivesResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    //MIRFAN@Appirio 10Feb12
    global class RenewalOffer{
        webservice string coverPrice;
        webservice string offeredSubId;
        webservice List<ProductOffer> products = new List<ProductOffer>();
        webservice WebserviceUtil.WSError wsError;
        webservice date SubscriptionStartDate;
        webservice boolean isGift;
    }

    global class ProductOffer{
        webservice string productName;
        webservice decimal weeklyPrice;
        webservice decimal monthlyPrice;
        webservice decimal totalPrice;
        webservice string duration;
        webservice decimal savingPercentageOnCoverPrice;
        webservice decimal savingAmountOnCoverPrice;
        webservice string productType;
    }

    global class ValidatePOCResult{
        webservice String POCStatus;
        webservice String TCode;
        webservice List<SubPrice> prices;
        webservice WebserviceUtil.WSError wsError;

        public ValidatePOCResult(String POCStatus, String TCode, List<SubPrice> prices ){
            this.POCStatus = POCStatus;
            this.TCode = TCode;
            this.prices = prices;
        }

        public ValidatePOCResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    global class GetActiveSubscriptionDetailsResult{
        webservice ActiveSubscription SubscriptionDetails;
        webservice WebserviceUtil.WSError wsError;

        public GetActiveSubscriptionDetailsResult(ActiveSubscription SubscriptionDetails){
            this.SubscriptionDetails = SubscriptionDetails;
        }

        public GetActiveSubscriptionDetailsResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    global class GetLapsedSubscriptionDetailsResult{
        webservice LapsedSubscription SubscriptionDetails;
        webservice WebserviceUtil.WSError wsError;

        public GetLapsedSubscriptionDetailsResult(LapsedSubscription SubscriptionDetails){
            this.SubscriptionDetails = SubscriptionDetails;
        }

        public GetLapsedSubscriptionDetailsResult(WebserviceUtil.WSError wsError){
            this.wsError = wsError;
        }
    }

    global class PaymentSchedules {
        webservice DateTime startDate;
        webservice DateTime paymentDate;
        webservice DateTime endDatePaymentSchedule;
        webservice DateTime endDateRnwlPaymentSchedule;
        webservice Decimal totalAmount;
        webservice String frequency;
        webservice String dateOffset;
        webservice String TSNumber;
        webservice String paymentScheduleId;
        webservice PaymentOrders paymntOrders;
    }

    global class PaymentOrders {
        webservice String orderId;
        webservice DateTime orderDate;
        webservice Decimal amount;
        webservice String status;
        webservice String paymentType;
    }

    /***************************************************************************************
    * @author Wiktor Czykin
    * @date 20/11/2015
    * @description Request parameters wrapper for create session request
    #############Change Log#############
    Modified by         Version     Change Date
    ***************************************************************************************/
    global class CreateSessionRequest{
        webservice String originator;
        webservice String returnUrl;
        webservice String functionId; //{AddSubscription,ProcessPayment,AddPaymentSchedule}
        webservice String serviceId;
        webservice String servicePriceId;
        webservice String paymentMethod;
        webservice String paymentFrequency;
        webservice String paymentStartDate;
        webservice String tsNumber;
        webservice String guid;
        webservice String email;
        webservice String title;
        webservice String firstName;
        webservice String lastName;
        webservice Decimal price;
        webservice String paymentCurrency;
        webservice String poc;
        webservice String tcode;
        webservice String incentiveId;
        webservice String incenticeDescription;
        webservice String subscriptionType;
        webservice String orderTakenByUser;
        webservice String orderTakenMethod;
        webservice String orderTakenCompany;
        webservice Integer subscriptionDuration;
        webservice String billingStreet;
        webservice String billingHomeHouseFlatNumber;
        webservice String billingHomeHouseName;
        webservice String billingTownCity;
        webservice String billingDistrict;
        webservice String billingPostCode;
        webservice String billingCountry;
        webservice List<CustomPaymentParams> customParameters;
    }

    /***************************************************************************************
    * @author Wiktor Czykin
    * @date 25/11/2015
    * @description Wrapper for custom parameters for CreateSession request //to pass through SAM parameters
    #############Change Log#############
    Modified by         Version     Change Date
    ***************************************************************************************/
    global class CustomPaymentParams{
        webservice String key;
        webservice String value;
    }

    /***************************************************************************************
    * @author Wiktor Czykin
    * @date 20/11/2015
    * @description Wrapper for CreateSession response
    #############Change Log#############
    Modified by         Version     Change Date
    ***************************************************************************************/
    global class CreateSessionResponse{
        webservice String guid;
        webservice Integer errorNumber;
        webservice String errorMessage;
    }
}
