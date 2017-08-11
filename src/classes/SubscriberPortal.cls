/***************************************************************************************
* @author Unknown
* @date Unknown
* @description
#############Change Log#############
Modified by     Version     Change Date
Cristina Popescu    1.1    21/06/2015  //create a map with linked subscription using all subscription linked to the subscriber
Michal Szewczyk     1.2    14/01/2016  //change Entitlements implementation to adhere to the new data model
Pawel Chrzanowski   1.3    24/03/2016  //modified getSubscriberAccountInformation() and calculateEntitlements() to include Registrants
Michal Szewczyk     1.3    28/04/2016  //change calculateEntitlements()
Michal Szewczyk     1.4    11/05/2016  //removed Subscription_Product__c from code
Michal Szewczyk     1.5    13/05/2016  //add temporary code in Subscriber() to handle '7DAY_SUBSCRIBER_IN_RENEWAL' ent for 25 May release
Mantas Grigaliunas  1.6    08/06/2016  //removed ipad related code
Michal Szewczyk     1.7    09/06/2016  //add CUSTOMER_PORTAL_OFFERS ent for in Renewal temporary solution
Mantas Grigaliunas  1.8    15/09/2016  //added DUMMY constant, modified getSubscriberAccountInformation, translateAttr
Wiktor Czykin       1.9    15/09/2016  //modified identify method. Added new calculateUnbundlingEntitlements() method.
Pawel Chrzanowski   2.0    22/09/2016  //fixed bug with null entitlements
Wiktor Czykin       2.1    06/10/2016  //modified Subscriber wrapper class and then reverted
Wiktor Czykin       2.2    14/12/2016  //modified Subscriber wrapper constructor entitlements fetching (pending canx)
Wiktor Czykin       2.3    31/01/2017  //added entitlements calculation for Registrants
****************************************************************************************/
global class SubscriberPortal{

    public static final String GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS = 'Is Legacy Identity Call Enabled';
    public static final String subscriberQuery = 'SELECT id, guid__c, subscriber_number_static__c, firstName, lastName, salutation, personEmail, PersonHomePhone, PersonMobilePhone, personHasOptedOutOfEmail, Do_Not_Mail__pc, PersonDoNotCall, X3rd_Party_Email_Offers__pc, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Promo_Email__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Partner_Promo_Email__c, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Digital_Status__c, Replatform_Digital_Status__c, Digital_Product_Type__c, Product__c, RecordTypeId  FROM Account a %%WHERE%% ';
    public static final String subscriptionsQuery = 'SELECT id, Subscription_Status__c, Lapsed_Status__c ,Start_Date__c, Subscription_Duration_Number__c, createdDate, Cancellation_Date__c, Subscriber__c,Product__c,Product__r.Name FROM Subscription__c %%WHERE%% ';


    private static final String errMsg = 'SubscriberPortal.cls: ';
    private static final List<String> TSTATUS = new List<String>{'SUCCESS','FAILURE'}; // transaction status
    private static final Integer NO_WEEKS = 13; // The number of weeks that defines what 'recently' mean e.g. recently lapsed
    private static final String DUMMY = 'DUMMY';
    public class SubscriberIdUsedException extends Exception {}

    public static boolean SAM_WS_UPDATE = false; // Static boolean used in triggers to determine if SAM initiated a record update vs us
    public static boolean SUB_TRIGGER_FIRED = false; // Static boolean used to stop triggers firing more than once in a single transaction

    public static final String SEVENDAY_ENT_PREFIX = '7DAY_SUBSCRIBER_';

    //SLP-64 - SB 18/05 - altered for new mapping
    public static final Map<String, String> attrMap = new Map<String,String>{'TITLE'=>'Salutation',
                                                                'FIRST_NAME'=>'firstName',
                                                                'LAST_NAME'=>'lastName',
                                                                'EMAIL_ADDRESS'=>'personEmail',
                                                                'CONTACT_BY_EMAIL'=>'TMG_Promo_Email__c',
                                                                'CONTACT_BY_POST'=>'TMG_Promo_Post__c',
                                                                'CONTACT_BY_PHONE'=>'TMG_Promo_Phone__c',
                                                                'MARKETING_OPT_IN_3RD'=>'TMG_Partner_Promo_Email__c',
                                                                'CONTACT_BY_SMS'=>'TMG_Promo_SMS__c',
                                                                'TMG_SALESFORCE_SUBSCRIPTION_ID'=>'subscriber_number_static__c',
                                                                'TMG_SUBSCRIBERS_OFFERS_OPT_IN'=>'TMG_Loyalty_Email__c',
                                                                'ADDRESS_LINE1'=>'PersonMailingStreet',
                                                                'ADDRESS_LINE3'=>'PersonMailingCity',
                                                                'COUNTY'=>'PersonMailingState',
                                                                'POSTCODE'=>'PersonMailingPostalCode',
                                                                'COUNTRY'=>'PersonMailingCountry',
                                                                'HOME_PHONE'=>'PersonHomePhone',
                                                                'MOBILE_PHONE'=>'PersonMobilePhone'
                                                };
    public static final Map<String,String> errMap = new Map<String,String>{'0001'=>'0001: NULL Parameter. [??]',
                                                                            '0002'=>'0002: Subscriber does not exist.',
                                                                            '0003'=>'0003: Unknown Entitlement.',
                                                                            '0004'=>'0004: Subscriber is attempting to update GUID',
                                                                            '9999'=>'9999: Unexpected Error.'};

    //SLP-64 - SB 18/05 - permissions fields - used to determine change for permissions update date
    static final List<String> permFields = new List<String>{'TMG_Promo_Email__c',
                                                            'TMG_Promo_Post__c',
                                                            'TMG_Promo_Phone__c',
                                                            'TMG_Partner_Promo_Email__c',
                                                            'TMG_Promo_SMS__c',
                                                            'TMG_Loyalty_Email__c'};

    public map<Id,Id> linkedSubs ;
    public static map<Id,Id> previousSubsMap;
    /* Util Methods */
    public static List<String> hasNull(Map<String,String> parmMap){
        boolean hasNull = false;
        List<String> errs = new List<String>();

        for(String k: parmMap.keySet()){
            String s = parmMap.get(k);
            if(s==null || s.trim().length()==0){
                hasNull = true;
                errs.add(errMap.get('0001').replace('??',k));
            }
        }

        return errs;
    }

    public static List<String> hasNull(Subscriber sub){
        boolean hasNull = false;
        List<String> errs = new List<String>();

        if(sub==null){
            hasNull = true;
            errs.add(errMap.get('0001').replace('??','subscriber'));
        }

        return errs;
    }


    public static String translateAttr(KeyValuePair kvp){
        //SLP-64 - SB 18/05 - remove fields from the opt out->in translation
        if(kvp.key.equalsIgnoreCase(DUMMY)){

            try{
                if(kvp.value.toUpperCase() == 'TRUE'){ // So reverse their value
                    return 'FALSE';
                } else{
                    return 'TRUE';
                }
            }catch (System.Nullpointerexception e){
                System.debug(errMsg + '[sfToSamTranslateAttr]'+ e.getMessage());
                return kvp.value;
            }
            //SLP-64 - SB 18/05 - add contact fields to the new translation + new fields
        } else if (kvp.key == 'TMG_SUBSCRIBERS_OFFERS_OPT_IN' ||
                kvp.key == 'CONTACT_BY_EMAIL' ||
                kvp.key == 'CONTACT_BY_POST' ||
                kvp.key == 'CONTACT_BY_PHONE' ||
                kvp.key == 'CONTACT_BY_SMS' ||
                kvp.key == 'MARKETING_OPT_IN_3RD'){
            try{
                if(kvp.value.toUpperCase() == 'TRUE'){ // So reverse their value
                    return '1';
                } else if(kvp.value.toUpperCase() == 'FALSE'){
                    return '0';
                } else if(kvp.value.toUpperCase() == '1'){
                    return 'TRUE';
                } else if(kvp.value.toUpperCase() == '0'){
                    return 'FALSE';
                }
            }catch (System.Nullpointerexception e){
                System.debug(errMsg + '[sfToSamTranslateAttr]'+ e.getMessage());
                return kvp.value;
            }
        }

        return kvp.value;
    }

    /* End of util methods */

    /* using minimal SOQL get hold of a list of Subscriber classes for a given set of Account Ids
    */
    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -
    #############Change Log#############
    Cristina Popescu 1.1   21/06/2015  //create a map with linked subscription using all subscription linked to the subscriber
    ****************************************************************************************/
    public static List<Subscriber> getSubscribers(Set<Id> AccountIds){

        Map<Id,Account> accounts = new Map<id,Account>((List<Account>)Database.query(SubscriberPortal.subscriberQuery.replace( '%%WHERE%%', 'WHERE Id IN :AccountIds' )));
        List<Subscription__c> subWorking = Database.query(SubscriberPortal.subscriptionsQuery.replace( '%%WHERE%%', 'WHERE subscriber__c IN :AccountIds' ) );

        //create a map that stores for each subscription the previous subscription is linked to(if any)
        previousSubsMap = checkForLinkedSubscriptions(subWorking);

        Map<Id,List<Subscription__c>> subs = new Map<Id,List<Subscription__c>>();
        Map<Id,Id> subsToAccs = new Map<Id,Id>();

        for(Subscription__c sub : subWorking){
            if(!subs.containsKey(sub.Subscriber__c))
                subs.put(sub.Subscriber__c, new List<Subscription__c>());

            subs.get(sub.Subscriber__c).add(sub);
            subsToAccs.put(sub.Id, sub.subscriber__c);
        }

        Map<Id,Map<Id,Date>> lapsedDates = new Map<Id,Map<Id,Date>>();

        if(subWorking != null){
            List<Subscription__c> lapsedSubs = [SELECT Id FROM Subscription__c WHERE Id IN :subWorking AND Subscription_Status__c = :Constants.SSTATUS_LAPSED];
            List<AggregateResult> dates = [SELECT ParentId, MAX(CreatedDate) FROM Subscription__History WHERE Field = 'Subscription_Status__c'  AND ParentId IN :subWorking GROUP BY ParentId];

            for(AggregateResult ar : dates ){
                Id accId = subsToAccs.get((Id)ar.get('ParentId'));

                if(!lapsedDates.containsKey(accId)){
                    lapsedDates.put(accId, new Map<Id,Date>());
                }

                lapsedDates.get(accId).put((Id)ar.get('ParentId'), ((Datetime)ar.get('expr0')).date());
            }
        }

        SAMHTTPSettings__c sp = SAMHTTPSettings__c.getInstance('ServiceKey');
        Application app = new Application(sp.Value__c);

        List<Subscriber> ret = new List<Subscriber>();

        for(Id acc : AccountIds){
            ret.add( new Subscriber(app, accounts.get(acc), subs.get(acc), lapsedDates.get(acc)) );
        }


        return ret;
    }

    /* Get all subscriber info for given details */
    public static Subscriber getSubscriber(String subscriberNo, String postcode){
        Account subscriber;
        List<Subscription__c> subscriptions;
        List<AggregateResult> dates;
        Map<Id,Date> lapsedDates = new Map<Id,Date>();
        Boolean validAccount = false;

        try{
            subscriber = database.query( SubscriberPortal.subscriberQuery.replace( '%%WHERE%%', 'WHERE Subscriber_Number_Static__c = :subscriberNo' ) );
            //Validate the tsnumber again?
            if(subscriber.Subscriber_Number_Static__c.equals(subscriberNo)){
                //Only match subscriber by post code if in uk, otherwise just validate by tsnumber.
                if(TMGUTil.isDataValid(subscriber.PersonMailingCountry) &&
                    subscriber.PersonMailingCountry.toLowerCase().equals('gb'))
                {
                    String newPostcode = FormatPostCode(postcode);
                    if(subscriber.PersonMailingPostalCode.equals(newPostcode)){
                        validAccount = true;
                    }
                }else{
                    if(TMGUTil.isDataValid(subscriber.Id)){
                        validAccount = true;
                    }
                }
            }else{
                validAccount = false;
            }
        }catch (Exception e){
            validAccount = false;
            System.debug(errMsg + 'Error while fetching account - ' + e);
        }

        if(!validAccount){
            subscriber = null;
            System.debug(errMsg + 'Cannot find account for tsNumber: ' + subscriberNo + ' - postCode: ' + postCode);
        }

        if(TMGUtil.isDataValid(subscriber) && subscriber.RecordTypeId != Constants.DigitalSubscriberRecordType()){
            try{
                ID i = subscriber.id;
                subscriptions = database.query( SubscriberPortal.subscriptionsQuery.replace( '%%WHERE%%', 'WHERE subscriber__c = :i' ) );
            }catch (Exception e){
                System.debug(errMsg + 'Error while fetching subscriptions - ' + e);
            }

            try{
                if(subscriptions != null){
                    List<Subscription__c> lapsedSubs = [SELECT Id FROM Subscription__c WHERE Id IN :subscriptions AND Subscription_Status__c = :Constants.SSTATUS_LAPSED];
                    dates = [SELECT ParentId, MAX(CreatedDate) FROM Subscription__History WHERE Field = 'Subscription_Status__c'  AND ParentId IN :lapsedSubs GROUP BY ParentId];
                }
            }catch(Exception e){
                System.debug(errMsg + 'Error while fetching lapsed dates - ' + e);
            }


            if(dates != null){
                for(AggregateResult ar : dates ){
                    lapsedDates.put((Id)ar.get('ParentId'), ((DateTime)ar.get('expr0')).date());
                }
            }
        }

        SAMHTTPSettings__c sp = SAMHTTPSettings__c.getInstance('ServiceKey');
        Application app = new Application(sp.Value__c);
        return new Subscriber(app, subscriber, subscriptions, lapsedDates);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Function - fetch subscriber information by TSnumber and Postcode
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         24/03/2016  //added more fields to fetch
    Mantas Grigaliunas  1.2         15/09/2016  //added the condition to skip post code validation if postcode value = 'dummy'
    ****************************************************************************************/
    public static Account getSubscriberAccountInformation(String subscriberNo, String postcode, Id logId){
        Account subscriberAccount;
        Boolean validAccount = false;

        try{
            subscriberAccount=[SELECT id, guid__c, subscriber_number_static__c, firstName, lastName, salutation, personEmail, PersonHomePhone, PersonMobilePhone, personHasOptedOutOfEmail, Do_Not_Mail__pc, PersonDoNotCall, X3rd_Party_Email_Offers__pc, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Promo_Email__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Partner_Promo_Email__c, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Digital_Status__c, Digital_Product_Type__c, Digital_Status__c, RecordTypeId, Recently_Lapsed_End_Date__c, Subscription_Status__c, Product__c, Product__r.Name FROM Account WHERE Subscriber_Number_Static__c =:subscriberNo];

            if(subscriberAccount.Subscriber_Number_Static__c.equals(subscriberNo)){
                //Only match subscriber by post code if in uk, otherwise just validate by tsnumber.
                if(TMGUTil.isDataValid(subscriberAccount.PersonMailingCountry)
                    && subscriberAccount.PersonMailingCountry.toLowerCase().equals('gb')
                    && !postcode.equalsIgnoreCase(DUMMY))
                {
                    String newPostcode = FormatPostCode(postcode);
                    if(subscriberAccount.PersonMailingPostalCode.equals(newPostcode)){
                        validAccount = true;
                    }
                }else{
                    if(TMGUTil.isDataValid(subscriberAccount.Id)){
                        validAccount = true;
                    }
                }
            }else{
                validAccount = false;
            }
        }catch (Exception e){
            validAccount = false;
            TMGUtil.updateWebServiceLog(logId, null, 'Error while fetching account - ' + e);

            System.debug(errMsg + 'Error while fetching account - ' + e);
        }

        if(!validAccount){
            subscriberAccount = null;
            TMGUtil.updateWebServiceLog(logId, null, 'Cannot find account for tsNumber: ' + subscriberNo + ' - postCode: ' + postCode);

            System.debug(errMsg + 'Cannot find account for tsNumber: ' + subscriberNo + ' - postCode: ' + postCode);
        }

        SAMHTTPSettings__c sp = SAMHTTPSettings__c.getInstance('ServiceKey');
        Application app = new Application(sp.Value__c);
        return subscriberAccount;
    }

    public static String FormatPostCode(String Postcode){
        String NewPostCode='';
        try{
                String ReplaceSpaceInMailingPostalCode = Postcode.replaceall(' ','');

                String[] ThisPostCode = ReplaceSpaceInMailingPostalCode.split('[0-9]',0);
                String LastDigit = ThisPostCode[ThisPostCode.size()-1];

                Integer LastOccurence = ReplaceSpaceInMailingPostalCode.lastIndexOf(LastDigit);
                if (LastOccurence >= 2){
                    NewPostCode = ReplaceSpaceInMailingPostalCode.substring(0,LastOccurence - 1) + ' ' + ReplaceSpaceInMailingPostalCode.substring(LastOccurence-1,ReplaceSpaceInMailingPostalCode.length() );
                    NewPostCode = NewPostCode.toUpperCase();
                }
                else //it is invalid
                    NewPostCode = Postcode;
            }
            catch (Exception err){
                system.debug(err);
                return '';
            }

        return NewPostCode;
    }

    public static String BuildAddressLine1(String value)
    {
        String result = value;
        List<String> lines = value.split('\\|');

        if(!lines.isEmpty()){
            result = '';
            for(String line :lines){
                result += line.trim() + '|';
            }
            result = result.substring(0, result.lastIndexOf('|')).trim();
        }

        return result;
    }

    public static Response updateSubscriber(Subscriber sub){
        Account subscriber;
        Response resp = new Response();

        try{
            string subNo = sub.no;
            subscriber = database.query( SubscriberPortal.subscriberQuery.replace( '%%WHERE%%', 'WHERE Subscriber_Number_Static__c = :subNo' ) );

            if(subscriber.guid__c <> null && subscriber.guid__c <> sub.guid){ // once a subscriber has a guid it cannot change
                throw new SubscriberIdUsedException();
            }

            subscriber.guid__c = sub.guid;

            boolean isPermChange = false;

            // Assign account to generic type for dynamic handling
            SObject obj = subscriber;
            for(KeyValuePair kvp: sub.attributes){
                System.debug('sp.kvp: '+kvp);
                String accFieldName = attrMap.get(kvp.key);
                if(accFieldName<> NULL && accFieldName.trim() <> '' && kvp.value <> NULL && accFieldName <> 'subscriber_number_static__c'){ // subscriber_number_static__c is read-only
                    //SLP-64 - SB 18/05 - check for permission change
                    for (String sChk : permFields) {
                        if (accFieldName == sChk) {
                            isPermChange = true;
                        }
                    }

                    String value = translateAttr(kvp);
                    if(kvp.key == 'ADDRESS_LINE1' && value != null){
                        String line1 = BuildAddressLine1(value);
                        obj.put(accFieldName, line1.replaceAll('\\|','\n').trim());
                    }

                    System.debug('value: '+value);
                    if(value=='TRUE')
                        obj.put(accFieldName, true);
                    else if (value=='FALSE')
                        obj.put(accFieldName, false);
                    else if (value=='0'){
                        obj.put(accFieldName,0);
                    }else if (value=='1'){
                        obj.put(accfieldName,1);
                    }
                    else
                        obj.put(accFieldName, value);
                }
            }

            SAM_WS_UPDATE = true;
            //SLP-64 - SB 18/05 - logic incorporated from trigger to handle DNC flag
            if( obj.get('TMG_Promo_Email__c') == 1 ||
                obj.get('TMG_Promo_Post__c') == 1 ||
                obj.get('TMG_Promo_Phone__c') == 1 ||
                obj.get('TMG_Partner_Promo_Email__c') == 1 ||
                obj.get('TMG_Loyalty_Email__c') == 1) {

                    obj.put('Do_Not_Contact__pc', false);

            }
            if (isPermChange) {
                obj.put('Permissions_Last_Change_Date__c',system.today());
            }

            System.debug('obj:' + obj);
            update obj;

            resp.status = TSTATUS[0];
        }catch (System.QueryException e){
            System.debug(errMsg + 'Error while fetching subscriber - '+e);
            resp.status = TSTATUS[1];

            List<String> nullErr = hasNull(new Map<String,String>{'Subscriber.no'=>sub.no});

            if(nullErr.size()>0){
                resp.errors = nullErr;
            }else{
                resp.errors = new List<String>{errMap.get('0002')};
            }
        }catch (SubscriberIdUsedException e){
            System.debug('Subscriber has already identified themselves.' + e.getMessage());
            resp.status = TSTATUS[1];

            resp.errors = new List<String>{errMap.get('0004')};
        }catch (System.Exception e){
            System.debug(errMsg + e);
            resp.status = TSTATUS[1];


            resp.errors = new List<String>{errMap.get('9999') + e.getMessage()};
        }

        return resp;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - method called by F*C to get current sub entitlements based on sfdc contents
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/09/2016 //added direct mapping  of product features to entitlements
    ****************************************************************************************/
    webservice static Subscriber identify(String subscriberNo, String postcode){
        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'SubscriberPortal.identify', new Map<String,Object>{'TsNumber' => subscriberNo, 'postcode' => postcode});
        Account sfAccountInformation;
        Subscriber subscriber = new subscriber();
        List<String> errs = hasNull(new Map<String, String>{ 'subscriberNo'=>subscriberNo, 'postcode'=>postcode});
        if(errs.size() > 0){
            System.debug(errMsg + errs);
            TMGUtil.logWebServiceResponse(logId, errMsg + errs);
            subscriber=new Subscriber(errs);
            return subscriber;
        }

        subscriberNo = subscriberNo.toUpperCase();
        sfAccountInformation = getSubscriberAccountInformation(subscriberNo, postcode, logId);//Any problems getting the information should be logged
        subscriber = initialiseSubscriberObjectLists(subscriber);

        //getSubscriberAccountInformation can return a null value which is a problem for calculateEntitlements
        if(sfAccountInformation != null){
            General__c setting = General__c.getInstance(GENERAL_LEGACY_IDENTIFY_ENTITLEMENTS);
            if(setting !=null && setting.Value_Boolean__c){
                subscriber = calculateEntitlements(sfAccountInformation, subscriber);
            }else{
                subscriber = calculateUnbundlingEntitlements(sfAccountInformation, subscriber);
            }
        }
        subscriber = returnAccountAttributes(sfAccountInformation,subscriber);
        TMGUtil.logWebServiceResponse(logId, subscriber);
        return subscriber;
    }

    /** Called by SAM if there are any errors from the bulk update
        No response to SAM needed as it's our problem
    */
    webservice static SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult bulkUpdateErrors(List<KeyValuePair> errors, string Status, string UUID){

        SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult();

        ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'bulkUpdateErrors',
                                                new Map<String,Object>{'errors.size' => errors.size(), 'Status' => Status, 'UUID' => UUID});

        if(errors.size() == 1)
            TMGUtil.logWebServiceDetail(logId, string.valueOf(errors));

        if(status == 'SUCCESS')
            return ret;

        try{
            Map<string,string> errorMap = new Map<string, string>();

            for(KeyValuePair kvp : errors){
                errorMap.put(kvp.Key, kvp.Value);
            }

            string emailBody = '<b>Org Id: ' + UserInfo.getOrganizationId() + '</b><br/><br/>UUID for request: ' + UUID +'<br/> Errors occurred whilst updating the following account' + (errors.size() == 1 ? '' : 's') + '<br/>';

            for(Account a : [SELECT Id, Guid__c, Subscriber_Number_Static__c FROM Account WHERE Guid__c != NULL AND Guid__c IN :errorMap.keySet()]){
                emailBody += '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + a.Id + '">' + a.Subscriber_Number_Static__c + '</a>  ' + (errorMap.get(a.Guid__c) == null ? '-- No Error Message sent from SAM --' : errorMap.get(a.Guid__c)) +'<br/>';
                errorMap.remove(a.Guid__c);
            }

            if(errorMap.size() > 0){
                emailBody += '<br/><br/><br/>Remaining items:<br/>' + errorMap;
            }

            TMGUtil.EmailUtil eml = new TMGUtil.EmailUtil(new List<String> {General__c.getInstance('Batch Subscription Failure User Email').Value__c});

            eml.htmlBody(emailBody)
               .subject('SAM Bulk Update Failures')
               .build()
               .sendEmail();

        } catch(Exception ex){
            ret = new SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult(new WebserviceUtil.WSException().getError());
            TMGUtil.logWebServiceDetail(logId, string.valueOf(ex));
        }

        TMGUtil.logWebServiceResponse(logId, ret);

        return ret;
    }

   private static Subscriber initialiseSubscriberObjectLists(Subscriber currentSubscriber)
   {
            currentSubscriber.entitlements = new List<String>();
            currentSubscriber.attributes = new List<KeyValuePair>();
            currentSubscriber.errors = new List<String>();
            return currentSubscriber;
   }

    public static Subscriber returnAccountAttributes(Account acc, Subscriber thisSubscriber){
        SObject obj = acc; // Var to help use account information dynamically

        for(String key: SubscriberPortal.attrMap.keySet()){
            String value;

            try{
                if(acc != null){
                    if(acc.Guid__c != null)
                        thisSubscriber.Guid = acc.Guid__c;
                    thisSubscriber.no = acc.Subscriber_Number_Static__c;
                    thisSubscriber.known = TRUE;
                }

                String fieldValue = String.valueOf(obj.get(SubscriberPortal.attrMap.get(key))); // Fetch the account field information for the mapped field name
                value = SubscriberPortal.translateAttr(new KeyValuePair(key,fieldValue)); // Perform translation of field values e.g. opt-in to opt-out translation

                // Street mapping for SAM - done here rather than transalate as it
                // needs to be reversed on the update
                if(key == 'ADDRESS_LINE1' && value != null)
                    value = value.replaceAll('\n','|').replaceAll(',','|');
            }
            catch (System.SObjectException e){ // No field mapping for Account
                System.debug(e + ' : '+key);
                value = null;
            }finally{
                thisSubscriber.attributes.add( new KeyValuePair(key, value));
            }
        }
        return thisSubscriber;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - update entitlement status based on the subscriber and subscription status
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Popescu    1.1         10/06/2015  //update code to move the entitlement to recently elapsed when the subscription wasn't renewed before the end date
    Cristina Popescu    1.2         26/06/2015  //COMBAU-1538 fix new sign up in SAM get wrong entitlement (Active instead of InRenewal)
    Michal Szewczyk     1.3         14/01/2016  // change to work with new data model
    Pawel Chrzanowski   1.4         24/03/2016  //modified to include Registrants
    Mantas Grigaliunas  1.5         08/08/2016  //removed ipad related code
    ****************************************************************************************/
    public static Subscriber calculateEntitlements(Account acc, Subscriber currentSubscriber){
        List<Subscription__c> subscriptionDetails = [SELECT Previous_Subscription__c, Subscription_Status__c,Previous_Subscription__r.Subscription_Status__c
                                                     FROM Subscription__c
                                                     WHERE Subscriber__c =: acc.Id
                                                     AND ((Subscription_Status__c =: Constants.SSTATUS_OFFERED
                                                     AND Previous_Subscription__c != null
                                                     AND Previous_Subscription__r.Subscription_Status__c =: Constants.SSTATUS_LAPSED)
                                                     OR Subscription_Status__c =: Constants.SSTATUS_IN_RENEWAL) limit 1];

        List<Entitlements__c> entitlementList = [Select Active_Entitlement_Value__c, Inactive_Entitlement_Value__c, InRenewal_Entitlement_Value__c, Pending_Entitlement_value__c, Recently_Inactive_Entitlement_Value__c, Pricing_Option_Product_Type__c  from Entitlements__c];
        String featureAsProductName = acc.Product__c != null ? EntitlementUtility.getDigitFeatureAsProductName(acc.Product__c) : acc.Digital_Product_Type__c;
        for(Entitlements__c thisEntitlement : entitlementList){
            if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName()) &&
               thisEntitlement.Pricing_Option_Product_Type__c == Constants.DIGITAL_PRODUCT_ALLDEVICES && featureAsProductName == Constants.DIGITAL_PRODUCT_ALLDEVICES){
                if (acc.Subscriber_Digital_Status__c == Constants.SSTATUS_ACTIVE && String.isNotBlank(thisEntitlement.Active_Entitlement_Value__c))
                    currentSubscriber.entitlements.add(thisEntitlement.Active_Entitlement_Value__c);
               else if (acc.Subscriber_Digital_Status__c == Constants.SSTATUS_INACTIVE && String.isNotBlank(thisEntitlement.Inactive_Entitlement_Value__c))
                    currentSubscriber.entitlements.add(thisEntitlement.Inactive_Entitlement_Value__c);
            }
            else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName()) &&
                    thisEntitlement.Pricing_Option_Product_Type__c == Constants.PRICING_WEBPACK_TYPE && featureAsProductName == Constants.DIGITAL_PRODUCT_WEBPACK){
                if (acc.Subscriber_Digital_Status__c == Constants.SSTATUS_ACTIVE && String.isNotBlank(thisEntitlement.Active_Entitlement_Value__c))
                    currentSubscriber.entitlements.add(thisEntitlement.Active_Entitlement_Value__c);
                else if (acc.Subscriber_Digital_Status__c == Constants.SSTATUS_INACTIVE && String.isNotBlank(thisEntitlement.Inactive_Entitlement_Value__c))
                    currentSubscriber.entitlements.add(thisEntitlement.Inactive_Entitlement_Value__c);
            }
            else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName()) &&
                    thisEntitlement.Pricing_Option_Product_Type__c == Constants.PRICING_PREMIUM_TYPE){
                if (acc.Subscription_Status__c == Constants.SSTATUS_ACTIVE && subscriptionDetails.isEmpty() && String.isNotBlank(thisEntitlement.Active_Entitlement_Value__c))
                    currentSubscriber.entitlements.add(thisEntitlement.Active_Entitlement_Value__c);
                //subscriber previous subscription expired
                else if (acc.Subscription_Status__c == Constants.SSTATUS_INACTIVE){
                    //allow user renew the new offered subscription
                    if (subscriptionDetails.size()>0 && subscriptionDetails[0].Subscription_Status__c == Constants.SSTATUS_OFFERED && String.isNotBlank(thisEntitlement.Recently_Inactive_Entitlement_Value__c)){
                        currentSubscriber.entitlements.add(thisEntitlement.Recently_Inactive_Entitlement_Value__c);
                    //dont allow user to renew subscription
                    }else if(String.isNotBlank(thisEntitlement.Inactive_Entitlement_Value__c)) {
                        currentSubscriber.entitlements.add(thisEntitlement.Inactive_Entitlement_Value__c);
                    }
                }
                else if (acc.Subscription_Status__c == Constants.SSTATUS_PENDING && String.isNotBlank(thisEntitlement.Pending_Entitlement_Value__c)){
                    currentSubscriber.entitlements.add(thisEntitlement.Pending_Entitlement_Value__c);
                }
                else if (subscriptionDetails.size()>0 && subscriptionDetails[0].Subscription_Status__c == Constants.SSTATUS_IN_RENEWAL && String.isNotBlank(thisEntitlement.InRenewal_Entitlement_Value__c)){
                    currentSubscriber.entitlements.add(thisEntitlement.InRenewal_Entitlement_Value__c);
                }

            }
            else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()) &&
                    thisEntitlement.Pricing_Option_Product_Type__c == Constants.DIGITAL_PRODUCT_ALLDEVICES &&
                    featureAsProductName == Constants.DIGITAL_PRODUCT_ALLDEVICES){
                if (acc.Digital_Status__c == Constants.SSTATUS_ACTIVE)
                    currentSubscriber.entitlements.add(thisEntitlement.Active_Entitlement_Value__c);
                else if(acc.Digital_Status__c == Constants.SSTATUS_INACTIVE)
                    currentSubscriber.entitlements.add(thisEntitlement.Inactive_Entitlement_Value__c);
            }
            else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()) &&
                    thisEntitlement.Pricing_Option_Product_Type__c == Constants.PRICING_WEBPACK_TYPE &&
                    featureAsProductName == Constants.DIGITAL_PRODUCT_WEBPACK){
                if (acc.Digital_Status__c == Constants.SSTATUS_ACTIVE)
                    currentSubscriber.entitlements.add(thisEntitlement.Active_Entitlement_Value__c);
                else if(acc.Digital_Status__c == Constants.SSTATUS_INACTIVE)
                    currentSubscriber.entitlements.add(thisEntitlement.Inactive_Entitlement_Value__c);
            }
        }
        return currentSubscriber;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - Unknown
    Version - 1.0
    Function - prepare list of entitlements for subscriber based on record state
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Subscriber calculateUnbundlingEntitlements(Account acc, Subscriber currentSubscriber){
        if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName())){
            return calculateEntitlements(acc, currentSubscriber);
        }
        Id productId;
        if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()) && acc.Digital_Status__c == Constants.SSTATUS_ACTIVE){
            productId = acc.Product__c;
        }else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())){
            Map<String, Subscription__c> mapSubscriptionsAgainstStatus = new Map<String, Subscription__c>();
            for(Subscription__c sub : [SELECT   Previous_Subscription__c,
                                                Subscription_Status__c,
                                                Previous_Subscription__r.Subscription_Status__c,
                                                Previous_Subscription__r.Product__c,
                                                Product__c
                                            FROM Subscription__c
                                         WHERE Subscriber__c =: acc.Id
                                         AND (
                                            Subscription_Status__c =: Constants.SSTATUS_PENDING
                                            OR Subscription_Status__c =: Constants.SSTATUS_ACTIVE
                                            OR Subscription_Status__c =: Constants.SSTATUS_IN_RENEWAL
                                            OR (Subscription_Status__c =: Constants.SSTATUS_PENDING_CANX AND Cancellation_Date__c >= :Date.today())
                                        )]){
                mapSubscriptionsAgainstStatus.put(sub.Subscription_Status__c, sub);
            }
            if(acc.Subscription_Status__c == Constants.SSTATUS_PENDING && mapSubscriptionsAgainstStatus.containsKey(Constants.SSTATUS_PENDING)){
                productId = mapSubscriptionsAgainstStatus.get(Constants.SSTATUS_PENDING).Product__c;
            }else if(acc.Subscription_Status__c == Constants.SSTATUS_ACTIVE){
                if(mapSubscriptionsAgainstStatus.containsKey(Constants.SSTATUS_ACTIVE)){
                    productId = mapSubscriptionsAgainstStatus.get(Constants.SSTATUS_ACTIVE).Product__c;
                }else if(mapSubscriptionsAgainstStatus.containsKey(Constants.SSTATUS_IN_RENEWAL)){
                    productId = mapSubscriptionsAgainstStatus.get(Constants.SSTATUS_IN_RENEWAL).Product__c;
                }else if(mapSubscriptionsAgainstStatus.containsKey(Constants.SSTATUS_PENDING_CANX)){
                    productId = mapSubscriptionsAgainstStatus.get(Constants.SSTATUS_PENDING_CANX).Product__c;
                }
            }
        }
        if(productId != null){
            Set<String> setFeatures = EntitlementUtility.mapProductIdWithEntitlements.get(productId);
            if(setFeatures != null && !setFeatures.isEmpty()){
                for(String entitlement : setFeatures){
                    currentSubscriber.entitlements.add(entitlement);
                }
            }
        }
        return currentSubscriber;
    }

    /***************************************************************************************
    Developer - Cristina Popescu
    Date - 21.06.2015
    Version - 1.0
    Function - get the map of linked subscriptions to be used when setting the recently lapsed status
    #############Change Log#############
    ****************************************************************************************/
    public static map<Id,Id> checkForLinkedSubscriptions(List<Subscription__c> subs){
        set<Id> subsID = new set<Id>();
        for(Subscription__c sub : subs){
            subsID.add(sub.Id);
        }
        previousSubsMap = new map<Id,Id>();
        for (Subscription__c curr : [SELECT Id,Previous_Subscription__c FROM Subscription__c WHERE Previous_Subscription__c IN: subsID AND Subscription_Status__c =: Constants.SSTATUS_OFFERED]){
            previousSubsMap.put(curr.Previous_Subscription__c,curr.Id);
        }

        return previousSubsMap;
    }

    global class Subscriber{
        webservice Application application;
        webservice String guid;
        webservice String pid;
        webservice String no;

        webservice boolean known;
        webservice String state;
        webservice List<KeyValuePair> attributes;
        webservice List<String> entitlements;

        webservice List<String> errors{get;set;}

        public Subscriber(Application a, String g, String p, String n, boolean k, boolean c, String s, List<KeyValuePair> attrs, List<String> ents){
            application = a;
            guid = g;
            pid = p;
            known = k;
            state = s;
            attributes = attrs;
            entitlements = ents;
        }

        public Subscriber(List<String> err){
            errors = err;
        }

        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 2.0
        Function - constructor for the subscription wrapper.
        #############Change Log#############
        Cristina Popescu    1.1 21/06/2015  //create a map with linked subscription using all subscription linked to the subscriber
        Cristina Anghenie   1.2 21/07/2015  //set entitlement for 13 weeks subscription
        Michal Szewczyk     1.3 14/01/2016  //change source from where product is taken to adhere to the new data model
        Michal Szewczyk     1.4 13/05/2016  //add temporary code to handle '7DAY_SUBSCRIBER_IN_RENEWAL' ent for 25 May release
        Mantas Grigaliunas  1.5 08/08/2016  //removed ipad related code
        Michal Szewczyk     1.6 09/06/2016  //add CUSTOMER_PORTAL_OFFERS ent for in Renewal temporary solution
        Pawel Chrzanowski   1.7 22/09/2016  //fixed bug with null entitlements
        Wiktor Czykin       1.8 06/10/2016  //removed extra condition for In Renewal status for entitlements calculation and then restored
        Wiktor Czykin       1.9 14/12/2016  //added condition for cancellation date for pending cancellation
        Wiktor Czykin       2.0 25/01/2017  //added entitlements setting for Registrant - but only for the product based approach
        ****************************************************************************************/
        public Subscriber(Application app, Account acc, List<Subscription__c> subs, Map<Id,Date> LapsedDatesFromSubscriptionHistory){
            entitlements = new List<String>();
            errors = new list<String>();
            if(subs == null)
                subs = new List<Subscription__c>();

            // Setup basics
            application = app;

            // If there is an account for this sub no, then we know about them.
            if(acc <> null){
                known = true;
                guid = acc.guid__c;
                no = acc.subscriber_number_static__c;

                // Setup attribute data
                SObject obj = acc; // Var to help use account information dynamically
                attributes = new List<KeyValuePair>();

                for(String key: SubscriberPortal.attrMap.keySet()){
                    String value;

                    try{
                        String fieldValue = String.valueOf(obj.get(SubscriberPortal.attrMap.get(key))); // Fetch the account field information for the mapped field name

                        value = SubscriberPortal.translateAttr(new KeyValuePair(key,fieldValue)); // Perform translation of field values e.g. opt-in to opt-out translation

                        // Street mapping for SAM - done here rather than transalate as it
                        // needs to be reversed on the update
                        if(key == 'ADDRESS_LINE1' && value != null)
                            value = value.replaceAll('\n','|').replaceAll(',','|');

                        // PP-1753
                        if(key == 'TMG_SUBSCRIBERS_OFFERS_OPT_IN') {

                            // PREMIUM : in case of no subscriptions against the subscriber, return inactive
                            if(acc.RecordTypeId != Constants.DigitalSubscriberRecordType()) {
                                if(subs.size() == 0) {
                                    value = 'PRINT-INACTIVE';
                                }
                            }

                            // DIGITAL : based on the product and in case of inactive subscriber, return inactive accordingly
                            if(acc.RecordTypeId == Constants.DigitalSubscriberRecordType()) {
                                if(acc.Subscriber_Digital_Status__c != 'Active') {
                                    if(acc.Digital_Product_Type__c == Constants.DIGITAL_PRODUCT_WEBPACK) {
                                        value = 'WEB-INACTIVE';
                                    } else {
                                        value = 'DIGITAL-INACTIVE';
                                    }
                                }
                            }
                        }
                    } catch (System.SObjectException e){ // No field mapping for Account
                        System.debug(e + ' : '+key);
                        value = null;
                    }finally{
                        attributes.add( new KeyValuePair(key, value));
                    }
                }
                if(EntitlementUtility.isNewEntitlementsActive()){
                    if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())){
                        //Loop through subs and check Active/ In Renewal, Pending, Pending Cancellation
                        List<Subscription__c> activeSubs = new List<Subscription__c>();
                        List<Subscription__c> pendingSubs = new List<Subscription__c>();
                        List<Subscription__c> pCancellationSubs = new List<Subscription__c>();

                        for(Subscription__c s: subs){
                            if(s.Subscription_Status__c == Constants.SSTATUS_ACTIVE || s.Subscription_Status__c == Constants.SSTATUS_IN_RENEWAL) {
                                activeSubs.add(s);
                            }
                            if(s.Subscription_Status__c == Constants.SSTATUS_PENDING) {
                                pendingSubs.add(s);
                            }
                            if(s.Subscription_Status__c == Constants.SSTATUS_PENDING_CANX) {
                                pCancellationSubs.add(s);
                            }
                        }
 
                        Set<String> entitlementSet;
                        if(activeSubs.size() > 0 && activeSubs[0].Product__c != null){
                            entitlementSet = EntitlementUtility.mapProductIdWithEntitlements.get(activeSubs[0].Product__c);
                        }else if(pendingSubs.size() > 0 && pendingSubs[0].Product__c != null){
                            entitlementSet = EntitlementUtility.mapProductIdWithEntitlements.get(pendingSubs[0].Product__c);
                        }else if(pCancellationSubs.size() > 0 && pCancellationSubs[0].Product__c != null && Date.today() < pCancellationSubs[0].Cancellation_Date__c){
                            entitlementSet = EntitlementUtility.mapProductIdWithEntitlements.get(pCancellationSubs[0].Product__c);
                        }

                        if(entitlementSet != null) entitlements.addAll(entitlementSet);
                    } else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType,Constants.RECTYPE_DIGISUB, Account.class.getName())){
                        if(acc.Subscriber_Digital_Status__c == Constants.SUBSCRIBER_ACTIVE_STATUS) {
                            if(acc.Product__c != null) {
                                entitlements.addAll(EntitlementUtility.mapProductIdWithEntitlements.get(acc.Product__c));
                            }
                        }
                    }else if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType,Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName())){
                        if(acc.Replatform_Digital_Status__c == Constants.SUBSCRIBER_ACTIVE_STATUS && acc.Product__c != null) {
                            entitlements.addAll(EntitlementUtility.mapProductIdWithEntitlements.get(acc.Product__c));
                        }
                    }
                } else {
                    // This is needed only for transiton period can be removed afterwards
                    // Print subscriber?
                    if(acc.RecordTypeId != RecordTypeUtility.getRecordTypeId(Account.SObjectType,Constants.RECTYPE_DIGISUB, Account.class.getName())){
                        // a list of the most recent subs for each sub product type
                        Map<String,Set<String>> tempEnts = new Map<String,Set<String>>(); // this will probably need to be a list of lists in future

                            // Add the entitlements for each product type to the list
                            String TempProduct;
                            for(Subscription__c s: subs){
                                String ent = getEntitlementState(s);
                                if(ent.contains('ERROR'))
                                    errors.add(errMap.get('0003'));
                                else{

                                    Set<String> entSet;
                                    String featureAsProductName = s.Product__c != null ? EntitlementUtility.getPrintFeatureAsProductName(s.Product__c) : Constants.SPRODUCT_7DAY;
                                    if ( featureAsProductName == Constants.SPRODUCT_7DAY
                                        || featureAsProductName == Constants.SPRODUCT_7DAY_SUB
                                        || featureAsProductName == Constants.SPRODUCT_7DAY_GIFT
                                        || featureAsProductName == Constants.SPRODUCT_SPECIAL156
                                        || featureAsProductName == Constants.SPRODUCT_13WEEK)
                                    {
                                        TempProduct = Constants.SPRODUCT_7DAY;
                                    }
                                    else
                                        TempProduct = featureAsProductName;

                                    if(tempEnts.get(TempProduct) == null){
                                        entSet = new Set<String>();
                                        entSet.add(ent);
                                    }else{

                                        entSet = tempEnts.get(TempProduct);
                                        entSet.add(ent);
                                    }
                                    tempEnts.put(TempProduct,entSet);
                                }
                            }

                            for(String product: tempEnts.keySet()){
                                Set<String> ents = tempEnts.get(product);
                                String entPrefix;
                                if(product == Constants.SPRODUCT_7DAY
                                    || product == Constants.SPRODUCT_7DAY_SUB
                                    || product == Constants.SPRODUCT_7DAY_GIFT
                                    || product == Constants.SPRODUCT_SPECIAL156
                                    || product == Constants.SPRODUCT_13WEEK)
                                {
                                    entPrefix = SEVENDAY_ENT_PREFIX;
                                    String active = entPrefix + Constants.SSTATUS_ACTIVE.toUpperCase();
                                    String inRenewal = entPrefix + Constants.SSTATUS_IN_RENEWAL.replace(' ','_').toUpperCase();
                                    String pending = entPrefix + Constants.SSTATUS_PENDING.toUpperCase();
                                    String recentlyLapsed = entPrefix + 'RECENTLY_LAPSED';
                                    String lapsed = entPrefix + Constants.SSTATUS_LAPSED.toUpperCase();

                                    if(ents.contains(active)){ // the order of the if statements forms symbolises the priority of each status
                                        entitlements.add(active);
                                        break;
                                    } else if(ents.contains(pending)){
                                        entitlements.add(pending);
                                        break;
                                    } else if(ents.contains(inRenewal)){
                                        entitlements.add(inRenewal);
                                        break;
                                    } else if(ents.contains(recentlyLapsed)){
                                        entitlements.add(recentlyLapsed);
                                        break;
                                    } else{
                                        entitlements.add(lapsed);
                                        break;
                                    }
                                }
                            }
                    }

                    // Digital subscriber
                    if(acc.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType,Constants.RECTYPE_DIGISUB, Account.class.getName())){
                        if(acc.Subscriber_Digital_Status__c != null && (acc.Product__c != null || acc.Digital_Product_Type__c != null)){
                            Boolean active = acc.Subscriber_Digital_Status__c == 'Active';
                            String featureAsProductName = acc.Product__c != null ? EntitlementUtility.getDigitFeatureAsProductName(acc.Product__c) : acc.Digital_Product_Type__c;
                            if(featureAsProductName == Constants.DIGITAL_PRODUCT_ALLDEVICES){
                                entitlements.add(active ? Constants.DIGITAL_SUBSCRIBER_ACTIVE : Constants.DIGITAL_SUBSCRIBER_INACTIVE);
                            } else if(featureAsProductName == Constants.DIGITAL_PRODUCT_WEBPACK){
                                entitlements.add(active ? Constants.WEBPACK_SUBSCRIBER_ACTIVE : Constants.WEBPACK_SUBSCRIBER_INACTIVE);
                            }
                        } else{
                            entitlements.add(Constants.DIGITAL_SUBSCRIBER_INACTIVE);
                        }
                    }
                }

            }else{ // Not a known subscriber
                known = false;
                errors.add(errMap.get('0002'));
            }
        }

        public Subscriber(){}


        /***************************************************************************************
        Developer - Unknown
        Date - Unknown
        Version - 1.2
        Function -
        #############Change Log#############
        Cristina Popescu1.1   21/06/2015  //set entitlement subscription to recently lapsed status only if the subscription is linked with an offered subscription
        Cristina Anghenie1.2  21/07/2015  //set entitlement for 13 weeks subscription
        ****************************************************************************************/
        // Returns String representation of SAM recognised entitlement + state on a per product basis.
        private String getEntitlementState(Subscription__c sub){
            String entitlement;
            String entPrefix;

            String product = sub.Product__c != null ? EntitlementUtility.getPrintFeatureAsProductName(sub.Product__c) : Constants.SPRODUCT_7DAY;
            String status = sub.subscription_status__c;
            System.debug('this status' + status + '  '+ product );

            if(product == Constants.SPRODUCT_7DAY
                || product == Constants.SPRODUCT_7DAY_SUB
                || product == Constants.SPRODUCT_7DAY_GIFT
                || product == Constants.SPRODUCT_SPECIAL156
                || product == Constants.SPRODUCT_13WEEK)
            {
                entPrefix = SEVENDAY_ENT_PREFIX;

                if(status == Constants.SSTATUS_OFFERED ||
                    status == Constants.SSTATUS_WITHDRAWN ||
                    status == Constants.SSTATUS_DECLINED ||
                    status == Constants.SSTATUS_CANX ||
                    status == Constants.SSTATUS_TEMP_SUSPENSION){

                entitlement = entPrefix + Constants.SSTATUS_LAPSED.toUpperCase();
                System.debug('1 ent');
                } else if (status == Constants.SSTATUS_LAPSED){
                    try{
                        if(String.isBlank(previousSubsMap.get(sub.Id))){
                            entitlement = entPrefix + Constants.SSTATUS_LAPSED;
                        } else {
                            entitlement = entPrefix + 'RECENTLY_LAPSED';
                        }
                        System.debug('2 ent');
                    }catch (System.QueryException e){
                        System.debug(errMsg + 'Error fetching subcription history: ' + e);
                        entitlement = entPrefix + 'ERROR';
                    }
                } else if (status == Constants.SSTATUS_ACTIVE){
                    System.debug('3 ent');
                    entitlement = entPrefix + Constants.SSTATUS_ACTIVE;

                } else if (status == Constants.SSTATUS_PENDING){
                    System.debug('4 ent');
                    entitlement = entPrefix + Constants.SSTATUS_PENDING;

                } else if (status == Constants.SSTATUS_IN_RENEWAL){
                    System.debug('5 ent');
                    entitlement = entPrefix + Constants.SSTATUS_IN_RENEWAL;

                } else if (status == Constants.SSTATUS_PENDING_CANX){
                    System.debug('6 ent' + sub.Cancellation_Date__c + ' ' +  Date.Today());
                    if(sub.Cancellation_Date__c > Date.Today()){
                        entitlement = entPrefix + Constants.SSTATUS_ACTIVE;
                    }else{
                        entitlement = entPrefix + Constants.SSTATUS_LAPSED;
                    }
                } else {
                    System.debug('7 ent');
                    entitlement = entPrefix + 'ERROR';
                }
            }
            else {
                entitlement = ''; //scenario subscriber has 7Day Active, Lapsed(any status) etc, but also has a different product that is not allowed by SAM which could be any status
            }

            System.debug('entitlement ' + entitlement);
            return entitlement.replace(' ','_').toUpperCase();
        }

    }

    global class Response{
        webservice String status{get;set;}
        webservice List<String> errors{get;set;}

        public Response(String s, List<String> e){
            status = s;
            errors = e;
        }

        public Response(){
            errors = new List<String>();
        }
    }

    global class Application{
        webservice String serviceId{get;set;}

        public Application(String s){
            serviceId = s;
        }
    }

    global class KeyValuePair{ // Maps can't be passed as arguments to webservice methods
        webservice String key;
        webservice String value;

        public KeyValuePair(String k,String v){
            key = k;
            value = v;
        }
    }
}