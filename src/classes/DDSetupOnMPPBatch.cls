/**
* @author MIrfan@Appirio, Plane 1.2;
* @date 08/05/2012
* @description Apex batch job to 
//////////////////////////////////////NOTE - DEVELOPER CONSOLE SCRIPT TO SCHEDULE JOBS\\\\\\\\\
//MIrfan@Appirio, 240612. Use following script to schedule Jobs run every 30 mins, with 10 min different between two jobs.
//////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
Integer iDelayInMins = 10;
Integer incCnt=0;
for(Integer i=1;i<=3;i++)
{
try
{
//UserManage   
    String chron_exp = '0 '+((i * iDelayInMins) + incCnt)+' * * * ?';
    MPPBulkUserManageScheduler  u = new MPPBulkUserManageScheduler();
    System.schedule('MPPBulkUserManageScheduler:' + i,chron_exp,u);
   
//GetPaymentDetails
    chron_exp = '0 '+(((i+1) * iDelayInMins) + incCnt)+' * * * ?';
    MPPBulkGetPaymentDetailsScheduler pg = new MPPBulkGetPaymentDetailsScheduler();
    System.schedule('MPPBulkGetPaymentDetailsScheduler:' + i,chron_exp,pg);

//PaymentSchedule
    chron_exp = '0 '+(((i+2) * iDelayInMins) + incCnt)+' * * * ?';
    MPPBulkPaymentScheduleScheduler  p = new MPPBulkPaymentScheduleScheduler();
    System.schedule('MPPBulkPaymentScheduleScheduler:' + i,chron_exp,p);
}catch(Exception ex){
//PaymentSchedule
    String chron_exp = '0 59 * * * ?';
    MPPBulkPaymentScheduleScheduler  p = new MPPBulkPaymentScheduleScheduler();
    System.schedule('MPPBulkPaymentScheduleScheduler:' + i,chron_exp,p);
    break;
}
incCnt+=(iDelayInMins*2);
}
//////////////////////////////////////SCRIPT - END\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#############Change Log#############
Modified by     	Version     Change Date
Wiktor Czykin   	1.1         27/05/2015  //some formatting clean-up,
Wiktor Czykin   	1.2         10/07/2015  //removed DD related batch  version (BuildRequestAndCalloutMPPDirectDebit method) as no longer valid,
                                        	also its related schedulable class was removed with Cristinas' clean-up
                                        	//removed BuildRequestAndCalloutMPPPaymentScheduleForLapsedSub() method and MPPBulkLapsedSubPaymentScheduleScheduler schedulable class that was calling it - useless method as Payonomy is already gone
Cristina Anghenie	1.3			25/09/2015	//add TSNumber to defaultEmail address to make it uniques when user doesnt have a email address
Wiktor Czykin   	1.4         28/09/2015  //modified getMPPServiceId() and BuildRequestAndCalloutMPPPaymentSchedule()
**/
global class DDSetupOnMPPBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global final String USER_MANAGE = 'UserManage';
    global final String PAYMENT_SCHEDULE = 'PaymentSchedule';
    global final String DIRECT_DEBIT = 'DirectDebit';
    global final String GETPAYMENT = 'GetPayment';
    global final String DD_COLLECTION_QUARTERLY= 'Quarterly';
    global final String DD_COLLECTION_MONTHLY= 'Monthly';
    global final String DD_COLLECTION_ANNUALLY= 'Annual';
    global final String MPP_PAYMENT_METHOD_DD= 'DirectDebit';
    global final String MPP_PAYMENT_METHOD_CARD= 'CreditCard';
    
    //////////////////////////////////////DO NOT MODIFY VALUE OF BELOW STATIC CONSTANTS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    ////MIrfan@Appirio. 240612. These Stages and Failures are reference from 4 other Scheduler classes, hence be aware of impact before amending.
    public static String MppDDCalloutStage_STAGE_1='UserManage';
    public static String MppDDCalloutStage_STAGE_2='DirectDebit';
    public static String MppDDCalloutStage_STAGE_3='PaymentSchedule';
    public static String MppDDCalloutStage_STAGE_4='GetPayment';
    public static String MppDDCalloutStage_STAGE_5='LapsedSubPaymentSchedule';
    public static String MppDDCalloutStage_STAGE_6='LapsedSubGetPayment';
    public static String MppDDCalloutStage_STAGE_FAILED='Failed';
    
    public static String MppDDCalloutStage_STAGE_1_FAILED = 'UserManage-Failed';
    public static String MppDDCalloutStage_STAGE_2_FAILED = 'DirectDebit-Failed';
    public static String MppDDCalloutStage_STAGE_3_FAILED = 'PaymentSchedule-Failed';
    public static String MppDDCalloutStage_STAGE_4_FAILED = 'LapsedSubPaymentSchedule-Failed';
    public static String MppDDCalloutStage_STAGE_5_FAILED = 'GetPayment-Failed';
    public static String MppDDCalloutStage_STAGE_6_FAILED = 'LapsedSubGetPayment-Failed';
        
    public static String SUBSCRIPTION_STATUS_PENDING = 'Pending';
    public static String SUBSCRIPTION_STATUS_OFFERED = 'Offered';
    public static String SUBSCRIPTION_STATUS_LAPSED = 'Lapsed';
    public static String SUBSCRIPTION_PAYMENT_TYPE_DD = 'Direct Debit';
    public static String DEFAULT_NO_EMAILID ='noemail@telegraph.co.uk';
    //////////////////////////////////////STATIC CONSTANTS - END\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
    global String query;
    global final String mppCalloutMethod;

    String MPP_URL;
    String MPP_BASE_URL; //NOTE: Base URL if formed by contactenating with extract URL with CustomSettings base URL.
    String MPP_BASE_URL_71;
    Integer MPP_LOGIN;
    String MPP_PASSWORD;
    String DIGITAL_ANNUALLY;
    String DIGITAL_MONTHLY;
    String PREMIUM_CONTINUOUS;  
    Integer CALLOUT_TIMEOUT=60000; 
    Boolean methodInvoked = true;

    //Constructor, accept's query and nature of method (i.e UserManage/DirectDebit/PaymentSchedule, which are declared constact global variables)
    global DDSetupOnMPPBatch(String q, string callMethod){
        query = q;
        mppCalloutMethod = callMethod;
        system.debug('@@@@@@@@ in Constructor DDSetupOnMPPBatch: '+query+'\n\n\n\n CallMethod: '+mppCalloutMethod);
    }

    //Batch Query executor
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - defines query locator for the batch. Contains extra custom settings logic to prevent parallel execution of the same type of batch job
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/06/2015  //removed references to removed processes - related to old payment methods
    ****************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bc) {  
        
        /* PP-1710 Changes */
        String dummyQuery = 'SELECT Id FROM User LIMIT 0';
        BatchNotification__c bn = null;

        if(mppCalloutMethod.equalsIgnoreCase(USER_MANAGE)) {
            
            // check if this batch is already running for this method
            bn = BatchNotification__c.getInstance('DDSetupOnMPPBatch_UM');
            if(bn == null) { // batch not running
                // call the method and create the flag for further use
                bn = new BatchNotification__c(name = 'DDSetupOnMPPBatch_UM');
                insert bn;
                system.debug('Setting custom setting for DDSetupOnMPPBatch_UserManage and calling method ..');
            } else {
                system.debug('DDSetupOnMPPBatch_UserManage call already in process ..');
                methodInvoked = false;
                query = dummyQuery;
            }
        }else if(mppCalloutMethod.equalsIgnoreCase(PAYMENT_SCHEDULE)) {

            // check if this batch is already running for this method
            bn = BatchNotification__c.getInstance('DDSetupOnMPPBatch_PS');
            if(bn == null) { // batch not running
                // call the method and create the flag for further use
                bn = new BatchNotification__c(name = 'DDSetupOnMPPBatch_PS');
                insert bn;
                system.debug('Setting custom setting for DDSetupOnMPPBatch_PaymentSchedule and calling method ..');
            } else {
                system.debug('DDSetupOnMPPBatch_PaymentSchedule call already in process ..');
                methodInvoked = false;
                query = dummyQuery;
            }
        }else if(mppCalloutMethod.equalsIgnoreCase(GETPAYMENT)) {
                        
            // check if this batch is already running for this method
            bn = BatchNotification__c.getInstance('DDSetupOnMPPBatch_GP');
            if(bn == null) { // batch not running
                // call the method and create the flag for further use
                bn = new BatchNotification__c(name = 'DDSetupOnMPPBatch_GP');
                insert bn;
                system.debug('Setting custom setting for DDSetupOnMPPBatch_GetPayment and calling method ..');
            } else {
                system.debug('DDSetupOnMPPBatch_GetPayment call already in process ..');
                methodInvoked = false;
                query = dummyQuery;
            }
        }
        
        System.debug('@@@@@@@@ in Start DDSetupOnMPPBatch: '+query+'\n\n\n\n CallMethod: '+mppCalloutMethod);
        return Database.getQueryLocator(query);
    }

    //Method to build custom ParamName and Value pair to be passed to MPP, using MPP Websrvice class SubscriptionParameter.
    private MPPDataContract2.SubscriptionParameter setMPPSubscriptionParameter(string paramName, string paramValue){
        MPPDataContract2.SubscriptionParameter subParamRec = new MPPDataContract2.SubscriptionParameter();
        subParamRec.ParameterName=paramName;
        subParamRec.ParameterValue=paramValue;
        
        return subParamRec;
    }

    //Method to build custom ParamName and Value pair to be passed to MPP, using MPP Websrvice class SubscriptionParameter.
    private MppGlobalIpayBusinessObjectsDataContr71.SubscriptionParameter setMPPSubscriptionParameter71(string paramName, string paramValue){
        MppGlobalIpayBusinessObjectsDataContr71.SubscriptionParameter subParamRec = new MppGlobalIpayBusinessObjectsDataContr71.SubscriptionParameter();
        subParamRec.ParameterName=paramName;
        subParamRec.ParameterValue=paramValue;
        
        return subParamRec;
    }
    
    //Method to build custom ParamName and Value pair to be passed to MPP, using MPP Websrvice class AccountParameter.
    private MPPDataContract2.AccountParameter setMPPAccountParameter(string paramName, string paramValue){
        MPPDataContract2.AccountParameter accParamRec = new MPPDataContract2.AccountParameter();
        accParamRec.ParameterName=paramName;
        accParamRec.ParameterValue=paramValue;
        
        return accParamRec;
    }    
    
    //Read MPP ServiceId set in Custom Settings
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - return serviceId for the reques
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         28/09/2015  //added serviceId fetching based on subscription tcode pricing options (currently supports continuous only as whole DD class)
                                            //previously it was only returning fixed premium service id
    ****************************************************************************************/
    private Integer getMPPServiceId(Subscription__c subscription, Map<Id, Map<String, Integer>> mapServiceId){
        Integer iServiceId = Integer.valueOf(PREMIUM_CONTINUOUS);
        if(mapServiceId != null && subscription != null && !mapServiceId.isEmpty() && subscription.TCode__c != null && subscription.Subscription_Duration_Number__c != null){
            String sKey = subscription.Subscription_Duration_Number__c + Constants.KEY_CONTINUOUS;
            if(mapServiceId.containsKey(subscription.TCode__c) && mapServiceId.get(subscription.TCode__c).containsKey(sKey) && mapServiceId.get(subscription.TCode__c).get(sKey) != null){
                iServiceId = mapServiceId.get(subscription.TCode__c).get(sKey);
            }
        }
        return iServiceId;
    }
    
    //Build MPP Webservice Request Object for UserManage and making callout.
    private void BuildRequestAndCalloutMPPUserManage(List<sObject> scope){
        List<Subscription__c> lstSubsToUpdate = new List<Subscription__c>();
        List<MPPBusinessobjectsBulkupdate2.UserManageRequest> lstUsrManageReq = new List<MPPBusinessobjectsBulkupdate2.UserManageRequest>();
        String strSubscriptionNumbers=''; 
        String strDataIssueSubNumbers='';
        String defaultEmail;
        //loop through .
        for(sObject rec: scope) {           
            Subscription__c subRec = (Subscription__c)rec;
            try{
            	 //Just to add to webservicelog for all the TSNumbers called out to MPP. 
            	defaultEmail = '';
                strSubscriptionNumbers+=subRec.Name+',';
                
                //Update stage field.
                subRec.MppDDCalloutAttemptCount__c = (subRec.MppDDCalloutStage__c==null)?1:subRec.MppDDCalloutAttemptCount__c+1;
                subRec.MppDDCalloutStage__c = MppDDCalloutStage_STAGE_1;
                subRec.MppDDLastCalloutDateTime__c = System.now(); 
                lstSubsToUpdate.add(subRec);
                
                MPPBusinessobjectsBulkupdate2.UserManageRequest userManageReq = new MPPBusinessobjectsBulkupdate2.UserManageRequest();
                MPPDataContract2.ArrayOfAccountParameter arrAccParameters = new MPPDataContract2.ArrayOfAccountParameter();
                arrAccParameters.AccountParameter = new List<MPPDataContract2.AccountParameter>();
                

                userManageReq.AccountTypeId=0;
                //yyyy-mm-dd
                DateTime dtime = (subRec.Subscriber__r.PersonBirthdate==null)?null:(DateTime)subRec.Subscriber__r.PersonBirthdate;
                
                userManageReq.DateOfBirth=(dtime!=null)?dtime.format('yyyy-MM-dd'):'';
                userManageReq.FirstName=subRec.Subscriber__r.FirstName;
                userManageReq.Surname=subRec.Subscriber__r.LastName;
                //David Glover@MPP. Gender cannot be null, it needs to be "NotKnown" (or "Male" or "Female").
                userManageReq.Gender=(subRec.Subscriber__r.Gender__pc==null)?'NotKnown':subRec.Subscriber__r.Gender__pc;
                userManageReq.HomeCountry=subRec.Subscriber__r.PersonMailingCountry;
                userManageReq.HomeCounty=subRec.Subscriber__r.PersonMailingState;
                userManageReq.HomeStreet=subRec.Subscriber__r.PersonMailingStreet;
                userManageReq.HomeTownCity=subRec.Subscriber__r.PersonMailingCity;
                userManageReq.HomePhoneNumber=subRec.Subscriber__r.PersonHomePhone;
                userManageReq.MobilePhoneNumber=subRec.Subscriber__r.PersonMobilePhone;
                userManageReq.HomePostcode=subRec.Subscriber__r.PersonMailingPostalCode;
                defaultEmail = DEFAULT_NO_EMAILID.substringBefore('@') + '+' + subRec.Subscriber__r.Subscriber_Number__c +'@'+ DEFAULT_NO_EMAILID.substringAfter('@');
                //David Glover @MPP. NoMarketingInformation needs to be either true or false. 
                //Hence defaulting to true;
                userManageReq.NoMarketingInformation=true;
                
                //Email Id should be set when User is setuped on MPP, if Subscriber is not having email then set default.
                userManageReq.Uki=(subRec.Subscriber__r.PersonEmail==null)?defaultEmail:subRec.Subscriber__r.PersonEmail;

                arrAccParameters.AccountParameter.add(setMPPAccountParameter('TSNumber',subRec.Subscriber__r.Subscriber_Number__c));
                
                if(subRec.Subscriber__r.Guid__c!=null) 
                {
                    arrAccParameters.AccountParameter.add(setMPPAccountParameter('GUID',subRec.Subscriber__r.Guid__c));
                }                   
                
                    userManageReq.CustomAccountParameters = arrAccParameters;
                lstUsrManageReq.add(userManageReq);
            }catch(Exception ex){strDataIssueSubNumbers+=subRec.Name+':'+ex.getMessage()+';\n';}
        }
            
        if(lstUsrManageReq.size()>0){
            MPPBusinessobjectsBulkupdate2.ArrayOfUserManageRequest arrUserManageRequest = new MPPBusinessobjectsBulkupdate2.ArrayOfUserManageRequest();
            arrUserManageRequest.UserManageRequest =lstUsrManageReq;
            system.debug('###########arrUserManageRequest##########'+arrUserManageRequest);                
            system.debug('MIrfan@Appirio arrUserManageRequest#############'+arrUserManageRequest);
            system.debug('MIrfan@Appirio mpp_BASE_URL#############'+mpp_BASE_URL);
            system.debug('MIrfan@Appirio CALLOUT_TIMEOUT#############'+CALLOUT_TIMEOUT);
                
            //MPP callout .
            MPPWcfServicesPublicBulkupdate.SOAPEndpoint mppCallout = new MPPWcfServicesPublicBulkupdate.SOAPEndpoint();
            mppCallout.endpoint_x=MPP_BASE_URL;
            mppCallout.timeout_x=CALLOUT_TIMEOUT;
            
            DateTime reqTime = System.now();
            try{
                MPPBusinessObjectsIPaydev.BulkUpdateResultData result = mppCallout.BulkUserManage(MPP_LOGIN, MPP_PASSWORD, arrUserManageRequest, false);
                system.debug('Response#####MPPBusinessObjectsIPaydev.BulkUpdateResultData result :'+result); 
                //ID logId = TMGUtil.logWebServiceRequest('Outbound', MPP_BASE_URL, 'BuildRequestAndCalloutMPPUserManage', new Map<String,Object>{'strSubscriptionNumbers' => strSubscriptionNumbers,'RequestTime' => reqTime}); 
                //TMGUtil.logWebServiceResponse(logId, result); 
            }catch(Exception ex){
                lstSubsToUpdate=new List<subscription__c>();
                system.debug('Exception########:'+ex);/*handle exception, or notify by email*/
                ID logId = TMGUtil.logWebServiceRequest('Outbound', MPP_BASE_URL, 'BuildRequestAndCalloutMPPUserManage', new Map<String,Object>{'strSubscriptionNumbers' => strSubscriptionNumbers,'RequestTime' => reqTime});
                TMGUtil.logWebServiceResponse(logId, ex); 
                SubscriptionsWebservicesHandlers.sendErrorEmail('DDSetupOnMPPBatch.BuildRequestAndCalloutMPPUserManage', logId, ex.getMessage(), ex);
            }
        }
            
        if(strDataIssueSubNumbers!=''){
           ID logId = TMGUtil.logWebServiceRequest('Outbound', MPP_BASE_URL, 'BuildRequestAndCalloutMPPUserManage', new Map<String,Object>{'InvalidDataException.strDataIssueSubNumbers' => strDataIssueSubNumbers});
        }
            
        if(lstSubsToUpdate.size()>0){
            try{
                String updateFailureRecords='';
                System.debug('#########lstSubsToUpdate#########'+lstSubsToUpdate);    
                //Update Subs with integration stage.
                //update lstSubsToUpdate;
                Database.SaveResult[] lstSR = database.update(lstSubsToUpdate,false);
                System.debug('#########lstSR#########'+lstSR);                    
                for(Database.SaveResult sr : lstSR){
                    if(!sr.isSuccess()){
                        updateFailureRecords+=sr.getErrors()+';\n';
                    }
                }
                System.debug('#########updateFailureRecords#########'+updateFailureRecords);                                        
                    //For any update failures.
                if(updateFailureRecords!=''){
                    System.debug('######updateFailureRecords#######'+updateFailureRecords);/*handle exception, or notify by email*/
                    ID logId = TMGUtil.logWebServiceRequest('Outbound', MPP_BASE_URL, 'BuildRequestAndCalloutMPPUserManage', new Map<String,Object>{'lstSubsToUpdate' => lstSubsToUpdate,'RequestTime' => System.now()});
                    TMGUtil.logWebServiceResponse(logId, updateFailureRecords); 
                }
            }catch(Exception ex){
                lstSubsToUpdate=new List<subscription__c>();
                system.debug('Exception#######'+ex);/*handle exception, or notify by email*/
                ID logId = TMGUtil.logWebServiceRequest('Outbound', MPP_BASE_URL, 'BuildRequestAndCalloutMPPUserManage', new Map<String,Object>{'lstSubsToUpdate' => lstSubsToUpdate,'RequestTime' => System.now()});
                TMGUtil.logWebServiceResponse(logId, ex); 
                SubscriptionsWebservicesHandlers.sendErrorEmail('DDSetupOnMPPBatch.BuildRequestAndCalloutMPPUserManage', logId, ex.getMessage(), ex);
            }
        }
    }
    
    //Build MPP Webservice Request Object for GetPaymentDetails and making callout.
    private void BuildRequestAndCalloutMPPGetPaymentDetails(List<sObject> scope){
        
        String paramMap; 
        try{
            //prepare parameters for the callout
            paramMap = buildParamMap((List<Subscription__c>)scope);
            System.debug('paramMap ::::'+paramMap);
            
            MPPInterfaceHTTP mppObj = new MPPInterfaceHTTP();
            //make callout
            List<MPPInterfaceHTTP.PaymentDetailResult> pdrList = mppObj.getBulkPaymentDetailResult(paramMap);
            
            //update the subscription with information recieved as reponse
            for(sObject rec: scope){
                Subscription__c subscripObj = (Subscription__c)rec;
                for(MPPInterfaceHTTP.PaymentDetailResult pdrObj: pdrList){
                    if(pdrObj.tsNumber == subscripObj.Subscriber__r.Subscriber_Number__c){
                        //If no value returned for required 3 fields then increment the Attempt count to retry in next batch execution.
                        if(pdrObj.firstCollectionAmount=='0' && pdrObj.firstCollectionDate =='0001-01-01T00:00:00' && pdrObj.premSubId=='0'){
                            subscripObj.MppDDCalloutAttemptCount__c=(subscripObj.MppDDCalloutAttemptCount__c==null)?0:subscripObj.MppDDCalloutAttemptCount__c+1;
                                
                            if(subscripObj.MppDDCalloutAttemptCount__c>3){
                                if(subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_3) || subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_5_FAILED)){
                                    subscripObj.MppDDCalloutStage__c = MppDDCalloutStage_STAGE_5_FAILED;
                                }else if(subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_5) || subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_6_FAILED)){
                                    subscripObj.MppDDCalloutStage__c = MppDDCalloutStage_STAGE_6_FAILED;
                                }
                            }
                            //Skip updating other fields and continue with rest of result
                            continue;
                        }

                        subscripObj.MPP_Premium_Subscription_ID__c = pdrObj.premSubId;
                        if(pdrObj.firstCollectionAmount != null){
                            subscripObj.MPP_DD_First_Payment_Amount__c = Decimal.valueOf(pdrObj.firstCollectionAmount);
                        }
                        //If LapsedSubPaymentSchedule was recent call then, update the Stage to LapsedSubGetPayment, instead of 4th call GetPayment.
                        if(subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_3) || subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_5_FAILED)){
                            subscripObj.MppDDCalloutStage__c = MppDDCalloutStage_STAGE_4;
                            subscripObj.Subscription_Status__c=SUBSCRIPTION_STATUS_PENDING;
                        } else if(subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_5) || subscripObj.MppDDCalloutStage__c.equalsIgnoreCase(MppDDCalloutStage_STAGE_6_FAILED)){
                            subscripObj.MppDDCalloutStage__c = MppDDCalloutStage_STAGE_6;
                        }
                        
                        //logic to populate MPP_DD_Next_Payment_Date__c 
                        if(pdrObj.collectionFreq != null && pdrObj.firstCollectionDate !=null){
                            System.debug('first collection date ::'+pdrObj.firstCollectionDate);
                            try{
                                subscripObj.MPP_DD_Next_Payment_Date__c = Date.valueOf(pdrObj.firstCollectionDate);
                            }catch(Exception ex){
                                System.debug('FirstCollectionDate parsing Exception:'+ex);
                            }
                        }                    
                    }
                } 
            }

            System.debug('#########scope#########'+scope);
            String updateFailureRecords='';

            List<Database.SaveResult> lstSR = Database.update(scope,false);
            Set<Id> setSubAcctsToUpdate = new Set<Id>();

            System.debug('#########lstSR#########'+lstSR);                     
            for(Database.SaveResult sr : lstSR){
                if(!sr.isSuccess()){
                    updateFailureRecords+=sr.getErrors()+';\n';
                }else{
                    setSubAcctsToUpdate.add(sr.getId());
                }
            }

            System.debug('#########updateFailureRecords#########'+updateFailureRecords);                    
            //For any update failures.
            if(updateFailureRecords!=''){
                System.debug('######updateFailureRecords#######'+updateFailureRecords);/*handle exception, or notify by email*/
                ID logId = TMGUtil.logWebServiceRequest('Outbound', mpp_BASE_URL, 'BuildRequestAndCalloutMPPGetPaymentDetails.SubUpdate', new Map<String,Object>{'scope' => scope,'RequestTime' => System.now()});
                TMGUtil.logWebServiceResponse(logId, updateFailureRecords); 
            }
                    
            //Update Account/Subscriber where Subscription was successfully updated.
            if(setSubAcctsToUpdate.size()>0){
                List<Account> lstAccToUpdate = new List<Account>();
                for(sObject rec: scope){
                    Subscription__c subscripObj = (Subscription__c)rec;
                    if(setSubAcctsToUpdate.contains(subscripObj.id)){
                        lstAccToUpdate.add(new Account(id=subscripObj.Subscriber__c,IsUsingMPP__c=true));
                    }
                }               
                    
                updateFailureRecords='';    
                List<Database.SaveResult> resultAcc = Database.update(lstAccToUpdate,false);

                for(Database.SaveResult sr : resultAcc){
                    if(!sr.isSuccess()){
                        updateFailureRecords+=sr.getErrors()+';\n';
                    }
                }               
                
                //For any update failures.
                if(updateFailureRecords!=''){
                    System.debug('######updateFailureRecords#######'+updateFailureRecords);/*handle exception, or notify by email*/
                    ID logId = TMGUtil.logWebServiceRequest('Outbound', mpp_BASE_URL, 'BuildRequestAndCalloutMPPGetPaymentDetails.AccountUpdate', new Map<String,Object>{'lstAccToUpdate' => lstAccToUpdate,'RequestTime' => System.now()});
                    TMGUtil.logWebServiceResponse(logId, updateFailureRecords); 
                    //SubscriptionsWebservicesHandlers.sendErrorEmail('DDSetupOnMPPBatch.BuildRequestAndCalloutMPPDirectDebit', logId, ex.getMessage(), ex);
                }               
            }
        }catch(Exception e){
            System.debug('DML Exception occured :: '+e.getMessage());
        }   
    }
     
     
    public String buildParamMap(List<Subscription__c> subs){
        String params = '';
        Integer i = 0;
        
        for(Subscription__c sub :subs){
            String step = ((i + 1) < 10 ? '0' + String.valueOf(i + 1) : String.valueOf(i + 1));
            params += 'AccountDetailsParamName' + step + '=TSNumber&' + 'AccountDetailsParamValue' + step + '=' 
                + sub.Subscriber__r.Subscriber_Number__c + (i == subs.size()-1 ? '' : '&');
            i++;    
        }
        
        return params;
    }
        
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function - Build MPP Webservice Request Object for PaymentSchedule and making callout.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         01/06/2015  //cleaned up a bit, improved logging (more details, specified more detailed types)
    Wiktor Czykin   1.2         10/07/2015  //added getMppDDOffsetNegative() call to replace fixed offset
    Wiktor Czykin   1.3         28/09/2015  //modified getMPPServiceId() call, added loop safe fetching of tcode related pricing options
    ****************************************************************************************/
    public void BuildRequestAndCalloutMPPPaymentSchedule(List<sObject> scope){
        List<Subscription__c> lstSubscriptions = (List<Subscription__c>)scope;
        List<Subscription__c> lstSubsToUpdate = new List<Subscription__c>();
        String strSubscriptionNumbers=''; 
        String strDataIssueSubNumbers='';
        Map<Id, String> mapSubscriptionIdToTSNumber = new Map<Id, String>();
        Map<Id, Map<String, Integer>> mapTCodeToPricingOptionServiceId = new Map<Id, Map<String, Integer>>();
        Set<Id> setTCodeIds = new Set<Id>();
        for(Subscription__c subRec: lstSubscriptions){           
            mapSubscriptionIdToTSNumber.put(subRec.Id, subRec.Subscriber__r.Subscriber_Number__c);
            //Just to add to webservicelog for all the TSNumbers called out to MPP. 
            strSubscriptionNumbers+=subRec.Name+',';
            if(subRec.TCode__c != null){
                setTCodeIds.add(subRec.TCode__c);
            }
        }
        try{
            for(Pricing_Options__c po : [select Id,
                                                TCodeManagement__c,
                                                Name,
                                                ServiceId__c, 
                                                Subscription_Type__c
                                            from Pricing_Options__c
                                            where TCodeManagement__c in :setTCodeIds
                                            and Flow_Type__c = :Constants.PRICINGOPTION_FLOWTYPE_SFDC
                                            and Product_Type__c = :Constants.PRODUCT_PREMIUM.toLowerCase()
                                        ]){
                if(!mapTCodeToPricingOptionServiceId.containsKey(po.TCodeManagement__c)){
                    mapTCodeToPricingOptionServiceId.put(po.TCodeManagement__c, new Map<String, Integer>());
                }
                if(po.ServiceId__c != null && String.isNotBlank(po.Subscription_Type__c)){
                    mapTCodeToPricingOptionServiceId.get(po.TCodeManagement__c).put(po.Subscription_Type__c, Integer.valueOf(po.ServiceId__c));
                }
            }
        }catch(Exception e){
            //fail silently
        }

        Map<Id, MppGlobalBusinessLogicCoreDataContrac71.AddDynamicPaymentScheduleRequest> mapPaymentScheduleReq = new Map<Id, MppGlobalBusinessLogicCoreDataContrac71.AddDynamicPaymentScheduleRequest>();
        //retrieve tcode pricing options 
        for(Subscription__c subRec : lstSubscriptions) {   
            try{
                //Update stage field.
                subRec.MppDDCalloutAttemptCount__c = (subRec.MppDDCalloutStage__c==null || subRec.MppDDCalloutStage__c.equalsIgnoreCase('DirectDebit'))?1:subRec.MppDDCalloutAttemptCount__c+1;
                subRec.MppDDCalloutStage__c = MppDDCalloutStage_STAGE_3;
                subRec.MppDDLastCalloutDateTime__c = System.now();
                subRec.Payment_Details_Received__c = true;
                
                Date dtPaymentStartDate;
                String strFrequency;
                String strPaymentMethod;
                Integer intPaymentDateOffset=0;
                
                System.debug('*****subRec.Subscriber__r.IsUsingMPP__c: ' + subRec.Subscriber__r.IsUsingMPP__c);
                System.debug('*****subRec.Previous_Subscription__r.MPP_Scheduled_First_Payment_Date__c: ' + subRec.Previous_Subscription__r.MPP_Scheduled_First_Payment_Date__c);
                             
                //Calculate the Schedule Payment start date
                //If this is MPP to MPP Renewal then read from Previous Subscription
                if(subRec.Subscriber__r.IsUsingMPP__c) {
                    //NOTE: Potential issue, if Subscriptions via Online Acquisition/Renewal does not update the Previous Subs payment date.
                    //If Previous Sub is having Scheduled First Payment Date then calculate to get the Payment Start Date for Offered Sub.
                    
                    /* Entry criteria and Payment Start Date retrieval code block 
                     * The Payment start date will now be fetched from MPP_CurrentPayScheduleEndDate__c field 
                     * instead of being calculated in Salesforce.
                     * All other logic remains BAU through out the code

                     * Entry criteria :
                     * - The account should be using MPP (parent entry criteria above)
                     * - The previous subscription should not have been paid by payonomy (Previous_Subscription__r.IsUsingMPP__c identifies the same) 
                     * - The previous subscription should be isContinuous__c flag as true 
                     * - The previous subscription status should be in 'In Renewal' 
                     */
                    if('True'.equalsIgnoreCase(subRec.Previous_Subscription__r.Is_Using_MPP__c) && subRec.Previous_Subscription__r.isContinuous__c && 'In Renewal'.equalsIgnoreCase(subRec.Previous_Subscription__r.Subscription_Status__c)) {
                        System.debug('TMGLOG::Account is Using MPP');
                        System.debug('TMGLOG::Previous Subs is Using MPP\nPrevious Subscription is Continuous\nPrevious Subs is In Renewal');                
                        System.debug('TMGLOG::Subscriber MPP Current Pay Schedule End Date - ' + subRec.Subscriber__r.MPP_CurrentPayScheduleEndDate__c);
                        
                        // get the payment start date as Account's MPP_CurrentPayScheduleEndDate__c
                        dtPaymentStartDate = subRec.Subscriber__r.MPP_CurrentPayScheduleEndDate__c;
                    } else {
                        System.debug('TMGLOG::Entry Criteria not met for this record, process other record. This record will not be sent to MPP ..');
                        continue;
                    }
                    /* END : Subscriptions BAU:PP-1615 Entry criteria and Payment Start Date retrieval code block */
                    System.debug('TMGLOG::dtPaymentStartDate: '+dtPaymentStartDate);
                    System.debug('TMGLOG::subRec.Previous_Subscription__r.MPP_DD_Frequency__c: '+subRec.Previous_Subscription__r.MPP_DD_Frequency__c);
                    
                    if(subRec.Previous_Subscription__r.MPP_DD_Frequency__c!=null){
                        System.debug('TMGLOG:: Previous MPP_DD_Frequency__c NOT NULL : '+subRec.Previous_Subscription__r.MPP_DD_Frequency__c);
                        strFrequency = (subRec.Previous_Subscription__r.MPP_DD_Frequency__c==null) ? null: (subRec.Previous_Subscription__r.MPP_DD_Frequency__c.equalsIgnoreCase('annually')?DD_COLLECTION_ANNUALLY:subRec.Previous_Subscription__r.MPP_DD_Frequency__c);
                        subRec.MPP_DD_Frequency__c = subRec.Previous_Subscription__r.MPP_DD_Frequency__c;
                    }else{
                        System.debug('TMGLOG::Previous MPP_CC_Frequency__c NOT NULL : '+subRec.Previous_Subscription__r.MPP_CC_Frequency__c);
                        strFrequency = (subRec.Previous_Subscription__r.MPP_CC_Frequency__c==null) ? null: (subRec.Previous_Subscription__r.MPP_CC_Frequency__c.equalsIgnoreCase('annually')?DD_COLLECTION_ANNUALLY:subRec.Previous_Subscription__r.MPP_CC_Frequency__c);
                        subRec.MPP_CC_Frequency__c = subRec.Previous_Subscription__r.MPP_CC_Frequency__c;
                    }
                    
                    subRec.PaymentDate__c = subRec.Previous_Subscription__r.PaymentDate__c;
                                    
                    strPaymentMethod = (subRec.Previous_Subscription__r.Payment_Type__c.equalsIgnoreCase(Constants.SUB_PMETHOD_DD))?
                                            MPP_PAYMENT_METHOD_DD:
                                            MPP_PAYMENT_METHOD_CARD;    
                    //Needed to ensure payment offset is not passed as 0       
                    intPaymentDateOffset=(subRec.Previous_Subscription__r.Payment_Type__c.equalsIgnoreCase(Constants.SUB_PMETHOD_DD))?Constants.getMppDDOffsetNegative():0;             
                }
                
                MppGlobalBusinessLogicCoreDataContrac71.AddDynamicPaymentScheduleRequest payReq = new MppGlobalBusinessLogicCoreDataContrac71.AddDynamicPaymentScheduleRequest();
                payReq.ClientUserId = subRec.Subscriber__r.Subscriber_Number__c;
                payReq.Description = 'Ongoing Collection';
                payReq.Frequency = strFrequency;
                payReq.PaymentDateOffset = intPaymentDateOffset;
                payReq.Currency_x = 'GBP';
                payReq.PaymentMethod = strPaymentMethod;
                payReq.ServiceId = getMPPServiceId(subRec, mapTCodeToPricingOptionServiceId);  
                payReq.EmailReceipt = false;
                payReq.StartDate = dtPaymentStartDate+'';
                payReq.TotalAmount = subRec.total_price__c;

                //Preserve Scheduled Payment date for future MPP to MPP Renewals.
                subRec.MPP_Scheduled_First_Payment_Date__c = dtPaymentStartDate;
                lstSubsToUpdate.add(subRec);

                //Set Subscription Custom parameters.
                MppGlobalIpayBusinessObjectsDataContr71.ArrayOfSubscriptionParameter arrSubParameters = new MppGlobalIpayBusinessObjectsDataContr71.ArrayOfSubscriptionParameter();
                arrSubParameters.SubscriptionParameter =  new List<MppGlobalIpayBusinessObjectsDataContr71.SubscriptionParameter>();
                arrSubParameters.SubscriptionParameter.add(setMPPSubscriptionParameter71('TCode',subRec.TCode__r.Name));
                arrSubParameters.SubscriptionParameter.add(setMPPSubscriptionParameter71('OrderTakenMethod',subRec.Order_Taken_Method__c));
                arrSubParameters.SubscriptionParameter.add(setMPPSubscriptionParameter71('OrderTakenCompany',subRec.Order_Taken_By_Company__c));
                arrSubParameters.SubscriptionParameter.add(setMPPSubscriptionParameter71('OrderTakenByUser',subRec.Order_Taken_By_User_Department__c));

                //Not sure whether we will get or have to pass for Renewal Subs.  
                /*payReq.CustomSubscriptionParameters.add(setMPPSubscriptionParameter('IncentiveId',));
                payReq.CustomSubscriptionParameters.add(setMPPSubscriptionParameter('IncentiveDescription',));*/

                payReq.CustomSubscriptionParameters = arrSubParameters;
                
                System.debug('TMGLOG::paymentScheduleRequest'+payReq);
                
                mapPaymentScheduleReq.put(subRec.Id, payReq);
                System.debug('MGLOG::mapPaymentScheduleRequest: '+mapPaymentScheduleReq);
            }catch(Exception ex){
                strDataIssueSubNumbers+=subRec.Name+':'+ex.getMessage()+';\n';              
                String customMessage='Error: ';
                String cancellationMethod='Migration Failure';                
                subrec.Subscription_Status__c = 'Pending Cancellation';
                subrec.Cancellation_Date__c = subrec.Start_Date__c.addDays(1);
                subrec.Cancellation_Method__c = cancellationMethod;
                subrec.Cancellation_Reason__c = 'Failed payment';
                subrec.Migration_Stage_failure__c=customMessage+ex.getMessage(); 
                subrec.MppDDCalloutStage__c=MppDDCalloutStage_STAGE_FAILED;
                update subrec;
                SubscriptionsWebservicesHandlers.DDSetupFailure(subRec.Subscriber__r.Subscriber_Number__c, 'Failed payment', null);
            }
        }

        WebService_Log__c psLog;
        if(!mapPaymentScheduleReq.isEmpty()){
            MppGlobalBusinessLogicCoreDataContrac71.ArrayOfAddDynamicPaymentScheduleRequest arrPay = new MppGlobalBusinessLogicCoreDataContrac71.ArrayOfAddDynamicPaymentScheduleRequest();
            arrPay.AddDynamicPaymentScheduleRequest = mapPaymentScheduleReq.values();
            System.debug('TMGLOG::payment schedule request:'+arrPay);   
                         
            //MPP Callout.
            MppGlobalWcfServicesPublicBulkUpdate71.SOAPEndpoint mppCallout = new MppGlobalWcfServicesPublicBulkUpdate71.SOAPEndpoint();
            mppCallout.endpoint_x=MPP_BASE_URL_71;
            mppCallout.timeout_x=CALLOUT_TIMEOUT;     
            DateTime reqTime = System.now();  


            try{
                MppGlobalIshopBusinessObjectsIpayDeve71.BulkUpdateResultData result = mppCallout.BulkAddDynamicPaymentSchedule(MPP_LOGIN, MPP_PASSWORD, arrPay, false);
                System.debug('Response########MppGlobalIshopBusinessObjectsIpayDeve71.BulkUpdateResultData result :'+result);
                psLog = TMGUtil.logWebServiceRequestSerialized( Constants.DIRECTION_OUTBOUND, 
                                                                MPP_BASE_URL_71, 
                                                                Constants.LOG_PAYMENTSCHEDULE_CALLOUT, 
                                                                new Map<String,Object>{'strSubscriptionNumbers' => strSubscriptionNumbers,'RequestTime' => reqTime, Constants.LOGVAR_REQUESTBODY => arrPay},
                                                                null,
                                                                null,
                                                                null);
                TMGUtil.logIndividualLogsForParent(psLog, mapPaymentScheduleReq, mapSubscriptionIdToTSNumber);
                TMGUtil.logWebServiceResponse(psLog.Id, result);
            }catch(Exception ex){
                lstSubsToUpdate=new List<subscription__c>();
                System.debug('Exception#######'+ex);/*handle exception, or notify by email*/
                psLog = TMGUtil.logWebServiceRequestSerialized(   Constants.DIRECTION_OUTBOUND, 
                                                                    MPP_BASE_URL, 
                                                                    Constants.LOG_PAYMENTSCHEDULE_CALLOUT_EXCEPTION,
                                                                    new Map<String,Object>{'strSubscriptionNumbers' => strSubscriptionNumbers,'RequestTime' => reqTime},
                                                                    null,
                                                                    null,
                                                                    null);
                TMGUtil.logWebServiceResponse(psLog.Id, ex); 
                SubscriptionsWebservicesHandlers.sendErrorEmail('DDSetupOnMPPBatch.BuildRequestAndCalloutMPPPaymentSchedule', psLog.Id, ex.getMessage(), ex);
            }
        }   
        
        if(strDataIssueSubNumbers!=''){
            TMGUtil.logWebServiceRequestSerialized( Constants.DIRECTION_OUTBOUND,
                                                    MPP_BASE_URL, 
                                                    Constants.LOG_PAYMENTSCHEDULE_DATAISSUES, 
                                                    new Map<String,Object>{'InvalidDataException.strDataIssueSubNumbers' => strDataIssueSubNumbers},
                                                    null,
                                                    null,
                                                    psLog.Id);
        }
        
        if(lstSubsToUpdate.size()>0){
            try{
                String updateFailureRecords='';
                System.debug('TMGLOG::lstSubsToUpdate#########'+lstSubsToUpdate);    
                //Update Subs with integration stage.
                Database.SaveResult[] lstSR = Database.update(lstSubsToUpdate,false);
            
                for(Database.SaveResult sr : lstSR){
                    if(!sr.isSuccess()){
                        updateFailureRecords+=sr.getErrors()+';\n';
                    }
                }
                System.debug('TMGLOG::lstSubsToUpdateUpdateFailureRecords#########'+updateFailureRecords);                
            
                if(updateFailureRecords!=''){
                    ID logId = TMGUtil.logWebServiceRequest(Constants.DIRECTION_OUTBOUND,
                                                            MPP_BASE_URL, 
                                                            Constants.LOG_PAYMENTSCHEDULE_DATAISSUES, 
                                                            new Map<String,Object>{'lstSubsToUpdate' => lstSubsToUpdate,'RequestTime' => System.now()});
                    TMGUtil.logWebServiceResponse(logId, updateFailureRecords); 
                }
            }catch(Exception ex){
                lstSubsToUpdate=new List<subscription__c>();
                ID logId = TMGUtil.logWebServiceRequest(Constants.DIRECTION_OUTBOUND,
                                                        MPP_BASE_URL, 
                                                        Constants.LOG_PAYMENTSCHEDULE_DATAISSUES_EXCEPTION, 
                                                        new Map<String,Object>{'lstSubsToUpdate' => strSubscriptionNumbers, 'RequestTime' => System.now(), Constants.LOGVAR_EXCEPTION => ex});
                SubscriptionsWebservicesHandlers.sendErrorEmail(Constants.LOG_PAYMENTSCHEDULE_DATAISSUES_EXCEPTION, logId, ex.getMessage(), ex);
            }
        }
    }
     
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Default batch execute method.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/07/2015  //removed old dd related lines
    ****************************************************************************************/ 
    global void execute(Database.BatchableContext bc, List<sObject> scope){

        //Load the MPP CustomSetting with ServiceIds.
        loadMPPCustomSettings();
        
        System.debug('TMGLOG:: in execute DDSetupOnMPPBatch: '+query+'\n\n\n\n CallMethod: '+mppCalloutMethod);
        System.debug('TMGLOG:: in execute DDSetupOnMPPBatch: scope size - ' + scope.size());
        
        /* Added and condition to check the size of the scope list. in case of dummyQuery, it will be empty and should not
         * invoke the respective methods to save extra processing in case the job is already running
         */
        //If is to Setup user on MPP, use BulkUserManger MPP callout.
        if(mppCalloutMethod.equalsIgnoreCase(USER_MANAGE) && scope.size() > 0){
            BuildRequestAndCalloutMPPUserManage(scope);            
        }
    
        //If is to DD Payment Schedule on MPP, use BulkAddDynamicPaymentSchedule MPP callout.
        if(mppCalloutMethod.equalsIgnoreCase(PAYMENT_SCHEDULE) && scope.size() > 0){
            BuildRequestAndCalloutMPPPaymentSchedule(scope);
        }
        
        //PP-1567 If is to Getpayment details on MPP, use GetPaymentDetails.ashx MPP callout.
        if(mppCalloutMethod.equalsIgnoreCase(GETPAYMENT) && scope.size() > 0){
            BuildRequestAndCalloutMPPGetPaymentDetails(scope);
        }
    }

    //Read customsettings for MPP
    private void loadMPPCustomSettings(){
        PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
        MPP_URL = customSetting.URL__c;
        MPP_BASE_URL = customSetting.baseURL__c+ 'interface/mpp/BulkUpdate/v7/BulkUpdate.SOAP.svc/soap';
        MPP_BASE_URL_71 = customSetting.baseURL__c+ 'interface/mpp/BulkUpdate/v7_1/BulkUpdate.SOAP.svc/soap';
        //MPP_BASE_URL_71 = 'https://paymentsuat.mppglobal.com/interface/mpp/BulkUpdate/v7_1/BulkUpdate.SOAP.svc/soap';
        MPP_LOGIN = Integer.valueOf(customSetting.login__c);
        MPP_PASSWORD = customSetting.password__c;
        DIGITAL_ANNUALLY = customSetting.Digital_Annually_ID__c;
        DIGITAL_MONTHLY = customSetting.Digital_Monthly_ID__c;
        PREMIUM_CONTINUOUS = customSetting.Premium_Continuous_ID__c;
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Default batch finish method.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/07/2015  //removed old dd related lines
    ****************************************************************************************/
    global void finish(Database.BatchableContext bc) {
        BatchNotification__c bn = null;
        // if method callout was successful, then delete the flag
        if(mppCalloutMethod.equalsIgnoreCase(USER_MANAGE)) {
            bn = BatchNotification__c.getInstance('DDSetupOnMPPBatch_UM');
            if(bn != null && methodInvoked == true) {
                delete bn;
                system.debug('Deleting custom setting DDSetupOnMPPBatch_UserManage in finish ..');
            } else {
                system.debug('Did not invoke the DDSetupOnMPPBatch_UserManage callout. Not deleting custom setting, returning ..');
            }
        }

        // if method callout was successful, then delete the flag
        if(mppCalloutMethod.equalsIgnoreCase(PAYMENT_SCHEDULE)) {
            bn = BatchNotification__c.getInstance('DDSetupOnMPPBatch_PS');
            if(bn != null && methodInvoked == true) {
                delete bn;
                system.debug('Deleting custom setting DDSetupOnMPPBatch_PaymentSchedule in finish ..');
            } else {
                system.debug('Did not invoke the DDSetupOnMPPBatch_PaymentSchedule callout. Not deleting custom setting, returning ..');
            }
        }

        // if method callout was successful, then delete the flag
        if(mppCalloutMethod.equalsIgnoreCase(GETPAYMENT)) {
            bn = BatchNotification__c.getInstance('DDSetupOnMPPBatch_GP');
            if(bn != null && methodInvoked == true) {
                delete bn;
                system.debug('Deleting custom setting DDSetupOnMPPBatch_GetPayment in finish ..');
            } else {
                system.debug('Did not invoke the DDSetupOnMPPBatch_GetPayment callout. Not deleting custom setting, returning ..');
            }
        }
    }
    
}