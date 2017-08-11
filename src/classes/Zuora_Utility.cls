/**
* Author:       Sally ElGhoul (Tquila)
* Date:         22/05/2015
* Description:  this class is a zuora Utility
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      16/01/2016
* Sally ElGhoul     02/02/2016 //modify getZuoraBillingAccounts to get the credit balance value
* Sally ElGhoul     16/02/2016 //modify the outbound product addition to avoid discount and charge discount rate plans
* Sally ElGhoul     17/02/2016 //for offers with zero discount, add directly the quote offer code record
* Sally ElGhoul     29/02/2016 //get the mid term discount reason value for subscription amendments
* Wiktor Czykin     11/08/2016 //modified getZuoraBillingAccounts()
* Wiktor Czykin     21/09/2016 //sendQuoteToZBilling() modified signature and added overloaded version
* Wiktor Czykin     10/05/2017 //offers related changes: addNewOfferCode() signature change!!, constant changed to label for label type of string, added frequency mapping
**/
public class Zuora_Utility {

    private static final Map<String, String> MAP_OFFER_FREQUENCY = new Map<String, String>{ 'annual'=> Constants.OFFER_FREQUENCY_ANNUALLY,
                                                                                            'annually' => Constants.OFFER_FREQUENCY_ANNUALLY,
                                                                                            'daily' => Constants.OFFER_FREQUENCY_DAILY,
                                                                                            'day' => Constants.OFFER_FREQUENCY_DAILY,
                                                                                            'monthly' => Constants.OFFER_FREQUENCY_MONTHLY,
                                                                                            'month' => Constants.OFFER_FREQUENCY_MONTHLY
    };

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        23/10/2015
    Function    Get All the quote charge groups
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static List<zqu.zChargeGroup> getQuoteChargeGroups(Id quoteId){
        //get All the charge groups on the quote
        return zqu.zQuoteUtil.getChargeGroups(quoteId);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        28/10/2015
    Function    Delete discount rate plan from the quote for specific offer code type
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static List<zqu.zChargeGroup> deleteDiscountRatePlansByOfferType(Id quoteId, List<zqu.zChargeGroup> lstQuoteChagreGroups, List<string> lstDeleteOfferCodeTypes){
        if(lstDeleteOfferCodeTypes!=null && lstDeleteOfferCodeTypes.size()>0){
            Set<Id> setQuoteRatePLanChargeIds = new Set<Id>();
            String whereClause='Quote__c=\''+quoteId+'\' and ';
            String typeCondition='';

            //the type condition
            for(String strOfferCodeType :lstDeleteOfferCodeTypes){
                typeCondition+=' Type__c=\''+strOfferCodeType+'\' or';
            }

            // Strip off the last or from the type condition if it exists.
            typeCondition=typeCondition.removeEnd('or');

            if(lstDeleteOfferCodeTypes.size()>1){
                whereClause+='('+typeCondition+')';
            }else{
                whereClause+=typeCondition;
            }

            List<Quote_Offer_Code__c> lstQuoteDefaultOfferCodes = OfferCode_Utility.getAllOfferCodes(whereClause);

            //loop on offer code and get the quote rate plan charge ids for them
            for(Quote_Offer_Code__c offerCodeObj : lstQuoteDefaultOfferCodes){
                if(!setQuoteRatePLanChargeIds.contains(offerCodeObj.Quote_Rate_Plan_Charge__c)){
                    setQuoteRatePLanChargeIds.add(offerCodeObj.Quote_Rate_Plan_Charge__c);
                }
            }

            //if the set of quote rate plan ids is not empty delete the chargegroups from zuora
            if(setQuoteRatePLanChargeIds!=null && setQuoteRatePLanChargeIds.size()>0){
                return deleteDiscountRatePlans(quoteId,lstQuoteChagreGroups,setQuoteRatePLanChargeIds);
            }
        }
        //nothing to delete return the same list
        return lstQuoteChagreGroups;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        23/10/2015
    Function    Delete a rate plan from the quote based on the rate plan charge Id
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void deleteQuoteRatePlan(Id quoteId, Set<Id> setQuoteRatePLanChargeIds, List<zqu.zChargeGroup> lstQuoteChagreGroups){
        List<zqu.zChargeGroup> lstQuoteDeleteChargeGroups = new List<zqu.zChargeGroup>();
        //Loop on the chagre group and check the name to GET all the discount charge groups and delete only the one that match the quoteRatePlanChargeId passed
        for(zqu.zChargeGroup chargeGroupObj: lstQuoteChagreGroups){
            //skip the removed products already and don't delete them
            if(chargeGroupObj.groupType!=zqu.zChargeGroup.TYPE_AMENDMENT_REMOVEPRODUCT && chargeGroupObj.groupType!=zqu.zChargeGroup.TYPE_RENEWAL_REMOVEPRODUCT){
                for(zqu.zCharge zChargeObj : chargeGroupObj.zCharges){

                     if(setQuoteRatePLanChargeIds.contains(zChargeObj.Id)){
                        lstQuoteDeleteChargeGroups.add(chargeGroupObj);
                    }
                }
            }
        }

        //If there any discount charge group found, delete them
        if(lstQuoteDeleteChargeGroups!=null && lstQuoteDeleteChargeGroups.size()>0){
            zqu.ZQuoteUtil.deleteChargeGroups(lstQuoteDeleteChargeGroups);
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        13/10/2015
    Function    This function is called to get the payment records using zuora Ids
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static list<Zuora.zObject> getZuoraPaymentRecords(Zuora.zApi zApi,list<string> lstZuoraPaymentIds){

        //the return zuora payments
        List <Zuora.zObject> lstZuoraPayments;

        //where clause
        string paymentWhereClause;

        //loop on all lstZuoraPaymentIds to form the where clause
        for(string strPaymentId : lstZuoraPaymentIds){
            if(string.isempty(paymentWhereClause)){
                paymentWhereClause='Id = \''+strPaymentId+'\'';
            }else {
                paymentWhereClause+=' or Id = \''+strPaymentId+'\'';
            }
        }

        if(!string.isempty(paymentWhereClause)){
            paymentWhereClause='Where '+paymentWhereClause;
        }else
        {
            throw new TMGUtil.GenericException('You cannot query Zuora Payments without a where clause.');
        }

        //form the soql query
        String paymentMethodZoql = 'SELECT PaymentMethodId, Id FROM Payment '+paymentWhereClause;

        if ( !Test.isRunningTest() ){
            //Query Zuora
            lstZuoraPayments = zApi.zquery(paymentMethodZoql);
            system.debug('check getZuoraPaymentRecords: '+lstZuoraPayments+' lstZuoraPaymentIds: '+lstZuoraPaymentIds);
        }else{
            try{
                lstZuoraPayments=new List <Zuora.zObject>();
                Zuora.zobject paymentObj=new zuora.zobject('Payment');
                paymentObj.setValue('PaymentMethodId','PaymentMethodIdValue');
                paymentObj.setValue('Id','PaymentIdValue');
                lstZuoraPayments.add(paymentObj);
            }
            catch(Exception ex){
                System.debug('### EXCEPTION DURING TESTING: ' + ex.getMessage());
            }

        }

        return lstZuoraPayments;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to create zbilling account if not created by CoreApi
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static string CreateZuoraBillingAccount(Zuora.zApi zApi,string sfAccountId){

        //query SF Account
        list<account> lstSfAccount=[select id,firstname,lastName,personHomePhone,personMobilePhone,
                                           personMailingCountry,personMailingPostalcode,
                                           personMailingStreet,personMailingState,
                                           personMailingCity from account where id = :sfAccountId];

        //returned Zbilling Account ID
        string zbillingAccountId='';
        string zuoraContactId='';

        if(lstSfAccount!=null && lstSfAccount.size()>0){
            try{
                //1. Create Account
                zbillingAccountId = CreateDraftZuoraAccount(zApi,lstSfAccount[0]);

                if(!string.isempty(zbillingAccountId)){
                    //2. Create Contacts
                    zuoraContactId=CreateZuoraContact(zApi,zbillingAccountId,lstSfAccount[0]);

                    if(!string.isempty(zuoraContactId)){
                        //3. Link Contacts with Account & Activate Account
                            ActivateZuoraAccount(zApi,zbillingAccountId,zuoraContactId);
                    }
                }
            }catch(exception ex){

                //rollback the contact if created and rollback the account if created
                rollbackZuoraAccountContactCreation(zApi,zbillingAccountId,zuoraContactId);
                system.debug('Error occured to create the new zuora Account and contact: '+ex );
                throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
            }
        }else {
            //throw friendly error message to the user
              throw new TMGUtil.GenericException(CONSTANTS.ERROR_INVALID_SALESFORCE_ACCOUNT_ID);
        }

        return zbillingAccountId;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to rollback the account or contact ceration in case an error occured during the 3 steps of account creation (draft account, contact, link contacts to account and activate)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void rollbackZuoraAccountContactCreation(Zuora.zApi zApi,string zuoraAccountId,string zuoraContactId){
        //rollback contact
        if(!string.isempty(zuoraContactId)){
            DeleteZuoraRecords(zApi,constants.ZUORA_CONTACT_OBJECT_NAME,new list<string>{zuoraContactId});
        }

        //rollback Account
        if(!string.isempty(zuoraAccountId)){
            DeleteZuoraRecords(zApi,constants.ZUORA_ACCOUNT_OBJECT_NAME,new list<string>{zuoraAccountId});
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to create a billing account in zuora with draft status
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static string CreateDraftZuoraAccount(Zuora.zApi zApi,Account sfAccount){

        // create account
        try{
            //add the account object to the list
            List<Zuora.zObject> objs = new List<Zuora.zObject> {CreateZuoraAccountInstance(sfAccount)};

            //call zuora create function
            List<Zuora.zApi.SaveResult> results;

            if ( !Test.isRunningTest() ){
                //test not running
                results=zApi.zcreate(objs);
            }else{
                //test is running so mock up response
                Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
                res.Success = true;
                res.Id = '1234';
                results = new List<Zuora.zApi.SaveResult>{res};
            }

            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success){
                    //get the newly created id
                    return result.Id;
                } else {
                    //failure
                    Zuora.zObject[] errors = result.errors;
                    for (Zuora.zObject error : errors) {
                        String errorCode = (String)error.getValue('Code');
                        String message = (String)error.getValue('Message');
                        System.debug('Method: CreateDraftZuoraAccount Error Code: '+ errorCode + ' Message: '+message);
                    }
                    throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
                }
            }
        } catch (exception ex) {
            System.debug('Method: CreateDraftZuoraAccount Error:'+ ex +' Line: '+ex.getLineNumber());
            //throw friendly error message to the user
            throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
        }
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to create a zuora account instance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Zuora.zObject CreateZuoraAccountInstance(Account sfAccount){
        Zuora.zObject acc = new Zuora.zObject(constants.ZUORA_ACCOUNT_OBJECT_NAME);

        //set Account Name
        string accountName='';
        if(!string.isempty(sfAccount.firstName)){
            accountName=sfAccount.firstName;
        }
        if(!string.isempty(sfAccount.LastName)){
            accountName+=' '+sfAccount.LastName;
        }
        acc.setValue(constants.ZUORA_ACCOUNT_NAME_FIELD_NAME, accountName);                                                            //set account name
        acc.setValue(constants.ZUORA_ACCOUNT_CRMID_FIELD_NAME,sfAccount.Id);                                                        //set the CrmId for this account
        acc.setValue(constants.ZUORA_ACCOUNT_BATCH_FIELD_NAME, constants.ZUORA_ACCOUNT_BATCH_FIELD_VALUE);                            //Set The batch
        acc.setValue(constants.ZUORA_ACCOUNT_CURRENCY_FIELD_NAME, constants.ZUORA_ACCOUNT_CURRENCY_FIELD_VALUE);                     // set the Currency
        acc.setValue(constants.ZUORA_ACCOUNT_BILLCYCLEDAY_FIELD_NAME, constants.ZUORA_ACCOUNT_BILLCYCLEDAY_FIELD_VALUE);             //set the BillCycleDay
        acc.setValue(constants.ZUORA_ACCOUNT_BCD_SETTING_OPTION_FIELD_NAME, constants.ZUORA_ACCOUNT_BCD_SETTING_OPTION_FIELD_VALUE);//set the BcdSettingOption
        acc.setValue(constants.ZUORA_ACCOUNT_PAYMENT_TETM_FIELD_NAME, constants.ZUORA_ACCOUNT_PAYMENT_TERM_FIELD_VALUE);             //set the paymentTerm
        acc.setValue(constants.ZUORA_ACCOUNT_STATUS_FIELD_NAME,constants.ZUORA_ACCOUNT_STATUS_FIELD_DRAFT_VALUE);                     //set the status value
        return acc;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to create the billing account's contact but another function will be called to link them together
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static string CreateZuoraContact(Zuora.zApi zApi,string zuoraAccountId,Account sfAccount){
        try{

            //create contact object zuora
            Zuora.zObject contactObj = CreateZuoraContactInstance(sfAccount);

            //fill contact fields
            contactObj.setValue(constants.ZUORA_CONTACT_ACCOUNTID_FIELD_NAME, zuoraAccountId);                        //set the zuora account id for the contact

            //add the contact object to the list
            List<Zuora.zObject> objs = new List<Zuora.zObject> {contactObj};

            //insert the list of objects
            List<Zuora.zApi.SaveResult> results ;

            if ( !Test.isRunningTest() ){
                results= zApi.zcreate(objs);
            }else{
                //test is running so mock up response
                Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
                res.Success = true;
                res.Id = 'Contact1234';
                results = new List<Zuora.zApi.SaveResult>{res};
            }

            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success){
                    //get the newly created id
                    return result.Id;
                } else {
                    //failure
                    Zuora.zObject[] errors = result.errors;
                    for (Zuora.zObject error : errors) {
                        String errorCode = (String)error.getValue('Code');
                        String message = (String)error.getValue('Message');
                        system.debug('Method: CreateZuoraContact Error Code: '+ errorCode + ' Message: '+message);
                    }
                    throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
                }
            }

        } catch (exception ex) {
            System.debug('Method: CreateZuoraContact Error:'+ ex );
            throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
        }
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to create a zuora Contact instance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Zuora.zObject CreateZuoraContactInstance(Account sfAccount){
        //create contact object zuora
        Zuora.zObject contactObj = new Zuora.zObject(constants.ZUORA_CONTACT_OBJECT_NAME);

        //fill contact fields
        contactObj.setValue(constants.ZUORA_CONTACT_FIRST_NAME_FIELD_NAME,sfAccount.firstName);                    //set the contact first name
        contactObj.setValue(constants.ZUORA_CONTACT_LAST_NAME_FIELD_NAME,sfAccount.LastName);                    //Set the contact Last Name
        contactObj.setValue(constants.ZUORA_CONTACT_HOME_PHONE_FIELD_NAME,sfAccount.personHomePhone);            //set the contact HomePhone
        contactObj.setValue(constants.ZUORA_CONTACT_MOBILE_PHONE_FIELD_NAME,sfAccount.personMobilePhone);        //set the contact MobilePhone
        contactObj.setValue(constants.ZUORA_CONTACT_COUNTRY_FIELD_NAME,sfAccount.personMailingCountry);            //set the contact country
        contactObj.setValue(constants.ZUORA_CONTACT_POSTAL_CODE_FIELD_NAME,sfAccount.personMailingPostalcode);    //set the contact postal code
        contactObj.setValue(constants.ZUORA_CONTACT_ADDRESS1_FIELD_NAME,sfAccount.personMailingStreet);            //set the contact address1
        contactObj.setValue(constants.ZUORA_CONTACT_CITY_FIELD_NAME,sfAccount.personMailingCity);                //set the contact City

        if(sfAccount.personMailingCountry==constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE){
            contactObj.setValue(constants.ZUORA_CONTACT_COUNTY_FIELD_NAME,sfAccount.personMailingState);        //Uk contacts set the county
        }else{
            contactObj.setValue(constants.ZUORA_CONTACT_STATE_FIELD_NAME,sfAccount.personMailingState);        //international contacts set the state
        }
        return contactObj;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This function is called to link the zuora contact to the billing account and activate the billing account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void ActivateZuoraAccount(Zuora.zApi zApi,string zbillingAccountId,string zuoraContactId){

        //specify the object we want to update in our case the account
        Zuora.zObject zAccount = new Zuora.zObject(constants.ZUORA_ZBILLING_ACCOUNT_OBJECT_NAME);

           //set the account id
        zAccount.setValue(constants.ZUORA_ZBILLING_ACCOUNT_ID_FIELD_NAME,zbillingAccountId); //an existing account

           //set the  bill to ID
        zAccount.setValue(constants.ZUORA_ACCOUNT_BILLTO_ID_FIELD_NAME, zuoraContactId);

        //set the Sold to ID
        zAccount.setValue(constants.ZUORA_ACCOUNT_SOLDTO_ID_FIELD_NAME, zuoraContactId);

        //set the status to Active
        zAccount.setValue(constants.ZUORA_ACCOUNT_STATUS_FIELD_NAME, constants.ZUORA_ACCOUNT_STATUS_FIELD_ACTIVE_VALUE);

       //if it is not a unit test class call the zupdate to update the billing account
       if ( !Test.isRunningTest() ) {
              List < Zuora.zApi.SaveResult > results = zApi.zUpdate(new List < Zuora.zObject > {zAccount});
              CheckZuoraResults(results,'ActivateZuoraAccount');
       }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        9/10/2015
    Function    This Generic method is called to delete record in Zuora
                Example: we will use it to rollback contact and account in case of exception while send to zbilling in one of the 3 steps of account creation
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void DeleteZuoraRecords(Zuora.zApi zApi,string ObjectName,List<String> deleteIDs){
        try {

            List<Zuora.zApi.DeleteResult> results ;

            if ( !Test.isRunningTest() ){
                results = zApi.zdelete(ObjectName,deleteIDs);
            }else {
                //test is running so mock up response
                Zuora.zApi.DeleteResult res = new Zuora.zApi.DeleteResult();
                res.Success = true;
                res.Id = '1234';
                results = new List<Zuora.zApi.DeleteResult>{res};
            }
            CheckZuoraResults(results,'DeleteZuoraRecords: '+ObjectName+' Records Ids: '+deleteIDs);
        } catch (Exception ex) {
            System.debug('Method: DeleteZuoraRecords Error:'+ ex );
            throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
        }
    }


    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        8/10/2015
    Function    This function is called to throw an exception if any error occured in zuora calls returned in results
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void CheckZuoraResults(List<Zuora.zApi.SaveResult> results,string MethodName){
        //looping on Zuora Results
        for (Zuora.zApi.SaveResult result : results) {
          //Not successful
          if (!result.Success){
              //failure
             //get the errors
             Zuora.zObject[] errors = result.errors;
             for (Zuora.zObject error : errors) {
                String errorCode = (String)error.getValue('Code');
                String message = (String)error.getValue('Message');
                system.debug('Method: '+MethodName+' Error Code: '+ errorCode + ' Message: '+message);
             }

             throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
          }
       }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        8/10/2015
    Function    This function is called to throw an exception if any error occured in zuora calls returned in results
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void CheckZuoraResults(List<Zuora.zApi.DeleteResult> results,string MethodName){
        //looping on Zuora Results
        for (Zuora.zApi.DeleteResult result : results) {
          //Not successful
          if (!result.Success){
              //failure
             //get the errors
             Zuora.zObject[] errors = result.errors;
             for (Zuora.zObject error : errors) {
                String errorCode = (String)error.getValue('Code');
                String message = (String)error.getValue('Message');
                system.debug('Method: '+MethodName+' Error Code: '+ errorCode + ' Message: '+message);
             }

              //throw friendly error message to the user
              throw new TMGUtil.GenericException(Label.General_Contact_administrator_error);
          }
       }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        28/09/2015
    Function    This function is called to retrieve all amendments of a subscription using the original subscription ID
                This function will get all the amendment from subscription version 1 to the latest version
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1            29/2/2016 get the Mid_term_Discount_Reason__c for amendment
    ****************************************************************************************/
    public static List <Zuora.zObject> getZuoraSubscriptionAmendments(Zuora.zApi zApi, string zOriginalSubscriptionID){

        //the return zuora subscription amendments
        List <Zuora.zObject> zuoraSubscriptionAmendmentsList=new List <Zuora.zObject>();

        if(string.isempty(zOriginalSubscriptionID)){
            return zuoraSubscriptionAmendmentsList;
        }

        //List of all the subscriptions using the original subscrition ID
        //because with each amendment a new subscription is created
        //the aim of this function is to get all the amendments on the original subscription
        //so we need to get all the amendment subscriptions from zuora first
        List <Zuora.zObject> zuoraSubscriptionList=getAllZuoraSubscriptionVersions(zApi,zOriginalSubscriptionID);

        //because ZOQL does not support the IN operator in the where clause
        //we will loop on all subscriptions and for the where clause to be (subscriptionId=value1 or subscriptionId=value2......)
        string subscriptionIdsWhereClause='';

        //loop on all subscription list including the original subscription itself
        for(Zuora.zObject subObj : zuoraSubscriptionList){
            if(string.isempty(subscriptionIdsWhereClause)){
                subscriptionIdsWhereClause='SubscriptionId = \''+string.valueof(subObj.getValue(constants.ZUORA_AMENDMENT_ID_FIELD_NAME))+'\'';
            }else {
                subscriptionIdsWhereClause+=' or SubscriptionId = \''+string.valueof(subObj.getValue(constants.ZUORA_AMENDMENT_ID_FIELD_NAME))+'\'';
            }
        }

        //form the soql query
        String amendmentZOQL = 'SELECT EffectiveDate, Description, Id,Name,Type,Status,TermStartDate,Mid_term_Discount_Reason__c FROM Amendment WHERE '+subscriptionIdsWhereClause;
        system.debug('check amendmentZOQL: '+amendmentZOQL);

        //Query Zuora
        zuoraSubscriptionAmendmentsList = zApi.zquery(amendmentZOQL);

        //return the list of zbilling list
        return zuoraSubscriptionAmendmentsList;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        29/09/2015
    Function    This function is called to retrieve all the subscriptions using the original subscription id
                 because with each amendment a new subscription with different id is created in zuora
                 but all subscription had the originalId field pointing to the original subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static list<Zuora.ZObject> getAllZuoraSubscriptionVersions(Zuora.zApi zApi, string zOriginalSubscriptionID){

        //list of zuora subscriptions
        List <Zuora.zObject> zuoraSubscriptionList;

        //form the soql query
        String subscriptionZOQL = 'SELECT Id,Version,Name,SubscriptionStartDate,SubscriptionEndDate FROM Subscription WHERE OriginalId = \''+zOriginalSubscriptionID+'\'';
         system.debug('check zuoraSubscriptionList: '+zuoraSubscriptionList);

         if ( !Test.isRunningTest() ){
            //Query Zuora
            zuoraSubscriptionList = zApi.zquery(subscriptionZOQL);
        }else{
            zuoraSubscriptionList=new List <Zuora.zObject>();
            Zuora.zobject subscriptionObj=new zuora.zobject('Subscription');
            subscriptionObj.setValue('OriginalId',zOriginalSubscriptionID);
            subscriptionObj.setValue('Version','1');
            subscriptionObj.setValue('Id','1223');
            subscriptionObj.setValue('Name','testing');
            zuoraSubscriptionList.add(subscriptionObj);
        }

        //return the list of zbilling list
        return zuoraSubscriptionList;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        22/10/2015
    Function    This function is called to retrieve the latest subscription version

    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Zuora.ZObject getLatestSubscriptionVersion(Zuora.zApi zApi, string zOriginalSubscriptionID){

        //get all subscription versions
        list<Zuora.ZObject> lstAllZuoraSubscriptionVersions=getAllZuoraSubscriptionVersions(zApi,zOriginalSubscriptionID);
        Zuora.ZObject latestZuoraSubscription;

        if(lstAllZuoraSubscriptionVersions!=null && lstAllZuoraSubscriptionVersions.size()>0){

            //set the latest subscription to the first one
            latestZuoraSubscription=lstAllZuoraSubscriptionVersions[0];

            //loop and check the latest
            for(Zuora.ZObject zSubscriptionObj: lstAllZuoraSubscriptionVersions){
                if(integer.valueof(zSubscriptionObj.getValue('Version'))>integer.valueof(latestZuoraSubscription.getValue('Version'))){
                    latestZuoraSubscription=zSubscriptionObj;
                }
            }
            return latestZuoraSubscription;
        }else{
            return null;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        29/06/2015
    Function    This function is called to retrieve the billing account in zuora using the salesforce account ID
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         11/08/2016  //removed substring for AccountId as CrmId in Zuora is in 18 chars case insensitive version
    ****************************************************************************************/
    public static List <Zuora.zObject> getZuoraBillingAccounts(Zuora.zApi zApi, String sfAccountId){
        List <Zuora.zObject> zuoraBillingAccList;
        String acczoql = 'SELECT Id, Name, AccountNumber, CreditBalance FROM Account WHERE Status = \''+Constants.SUBSCRIBER_ACTIVE_STATUS+'\' AND CrmId = \'' + sfAccountId + '\'';

        if (!Test.isRunningTest()){
            zuoraBillingAccList = zApi.zquery(acczoql);
        }else{
            zuoraBillingAccList=new List <Zuora.zObject>();
            Zuora.zobject accountObj=new zuora.zobject('Account');
            accountObj.setValue('CrmId',sfAccountId.substring(0, 15));
            accountObj.setValue('Status','Active');
            accountObj.setValue('Id','1223');
            accountObj.setValue('Name','testing');
            accountObj.setValue('AccountNumber','123232');
            zuoraBillingAccList.add(accountObj);
        }
        return zuoraBillingAccList;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        9/07/2015
    Function    This function is called to update the quote electronic payment ID field
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void updateQuoteElectornicPayment(string quoteId,string PaymentMethodId){

        //1. update the quote electronic payment field before sending to zbilling
        list<zqu__Quote__c> lstQuote=[select zqu__ElectronicPaymentMethodId__c from zqu__Quote__c where id=:quoteId];
        if(lstQuote!=null && lstQuote.size()>0){
            lstQuote[0].zqu__ElectronicPaymentMethodId__c=PaymentMethodId;
            update lstQuote[0];
        }
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/09/2016
    Function    This function is called to send quote to z-billing - overloaded method to support old invocations
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Map<Boolean, String> sendQuoteToZBilling(String quoteId, String sfAccountId, String zuoraAccountId, String paymentMethodID){
        return sendQuoteToZBilling(quoteId, sfAccountId, zuoraAccountId, paymentMethodID, null);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        29/06/2015
    Function    This function is called to send quote to z-billing
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         22/09/2016  //added extra parameter to method signature so that extra processing on the result can be done by the caller.
    ****************************************************************************************/
    public static Map<Boolean, String> sendQuoteToZBilling(String quoteId, String sfAccountId, String zuoraAccountId, String paymentMethodID, List<zqu.zQuoteUtil.zBillingResult> results){
        Map<Boolean, String> mapResultStatusMessage = new Map<Boolean, String>();
        // Retrieve config information
        Map<String, Object> zqconfig = zqu.zQuoteUtil.getZuoraConfigInformation();

        List<zqu.zQuoteUtil.ZBillingQuoteCollection> quotes = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>();
        zqu.zQuoteUtil.ZBillingQuoteCollection quote = new zqu.zQuoteUtil.ZBillingQuoteCollection();
        quote.sfdcAccountId = sfAccountId; // SFDC CRM Account ID
        quote.zAccountId = zuoraAccountId; // Zuora Billing Account ID
        //Prepare the zbilling quote request for thew zbilling quote collection object
        quote.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();

        zqu.zQuoteUtil.ZBillingQuoteRequest req = new zqu.zQuoteUtil.ZBillingQuoteRequest();
        req.sfdcQuoteId = quoteId; // SFDC Quote ID
        if(!String.isEmpty(paymentMethodID)){
            req.paymentMethodId = paymentMethodID; //to create the payment just entered as electric payment method to the account in zuora
        }

        //Set generate invoice flag on request
        req.generateInvoice = (Boolean) zqconfig.get('Generate_Invoice__c');
        req.setNewPaymentAsDefault = true; //to set the new payment method created as the default payment method to the account in zuora
        req.enableAccountAutoPay = true; //set the auto-pay field to true for the account in zuora
        req.processPayment = true;//Specifies whether or not the payment for this subscription should be processed when sent to Z-Billing
        zqu__Quote__c tempQuote = [select Id, zqu__Service_Activation_Date__c from zqu__Quote__c where Id =:quoteId];
        req.effectiveDate = tempQuote.zqu__Service_Activation_Date__c;

        quote.quoteRequests.add(req);
        quotes.add(quote);

        List<zqu.zQuoteUtil.zBillingResult> localResults = zqu.zQuoteUtil.sendToZBilling(quotes);
        //loop through the zbilling result - should actually only have one response as we always pass single quote
        for( zqu.zQuoteUtil.zBillingResult result : localResults ) {
           //if submit to zbilling is successfull, update the subscription record related quote field
           if(results != null){
               results.add(result);
           }
           if(result.success){
               //if the quote we just submitted to zbilling has a master quote which means it is not the first quote and it is amendment
               //we need to get the subscription record whose master quote is the same
               //and then we update the related quote field with this quote
               System.debug('check sendtoZbilling result: '+result);
               List<zqu__Quote__c> lstQuote = [select Id, zqu__SubscriptionType__c, Master_Quote__c, Outbound_POC__c from zqu__Quote__c where Id = :result.sfdcQuoteId];
               if(lstQuote!=null && lstQuote.size()>0 ){
                   if(!String.isEmpty(lstQuote[0].Outbound_POC__c)){
                       //set the subscription acquired flag of the POC to true
                       List<POC__c> lstPoc=[select id,Subscription_Acquired__c from POC__c where id=:lstQuote[0].Outbound_POC__c];
                       if(lstPoc!=null && lstPoc.size()>0){
                           lstPoc[0].Subscription_Acquired__c=true;
                           update lstPoc[0];
                       }
                   }
                   //master quote is empty which means it is not the first quote and it is amendment
                   if(!String.isEmpty(lstQuote[0].Master_Quote__c)){
                       //get the subscription record which master quote is the same master quote of the submitted quote
                       List<Zuora__Subscription__c> lstSubscription = [select Id, Related_Quote__c,Master_Quote__c from Zuora__Subscription__c where Master_Quote__c=:lstQuote[0].Master_Quote__c];
                       if(lstSubscription!=null && lstSubscription.size()>0){
                           //relate the subscription record to the quote we just submitted to zbilling
                           lstSubscription[0].Related_Quote__c=result.sfdcQuoteId;
                           update lstSubscription[0];
                       }
                   }
               }
           }
           if(!mapResultStatusMessage.containskey(result.success)){
             mapResultStatusMessage.put(result.success, result.message);
           } else {
             String resultMessage = mapResultStatusMessage.get(result.success);
             resultMessage+=result.message;
             mapResultStatusMessage.remove(result.success);
             mapResultStatusMessage.put(result.success,resultMessage);
           }
        }
        return mapResultStatusMessage;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////Payment Gateway Helper Functions//////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////
    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        07/10/2015
    Function    This function is called to get the paymentgateway value (String) for a payment method by checking the country, and the payment type
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static string getPaymentMethodGatewayValue(Zuora.zApi zApi,string zPaymentMethodId){
        string ZuoraPaymentGatewayValue='';

        //the return zuora payment methods
        List <Zuora.zObject> zuoraPaymentMethodList;

        //form the soql query
        String paymentMethodZoql = 'SELECT CreditCardCountry, Type, Id FROM PaymentMethod WHERE Id = \'' +zPaymentMethodId + '\'';

        if ( !Test.isRunningTest() ){
            //Query Zuora
            zuoraPaymentMethodList = zApi.zquery(paymentMethodZoql);
            system.debug('check zuoraPaymentMethodList: '+zuoraPaymentMethodList+' payment ID: '+zPaymentMethodId);
        }else{
            zuoraPaymentMethodList=new List <Zuora.zObject>();
            Zuora.zobject paymentMethodObj=new zuora.zobject('PaymentMethod');
            paymentMethodObj.setValue('Type',constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
            paymentMethodObj.setValue('CreditCardCountry',constants.UNITED_KINGDOM_COUNTRY_NAME_VALUE);
            zuoraPaymentMethodList.add(paymentMethodObj);
        }

        if(zuoraPaymentMethodList!=null && zuoraPaymentMethodList.size()>0){
            if(zuoraPaymentMethodList[0].getValue('Type')==Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE){

                //if the payment method type is bank transfer so use the direct debit gateway value
                ZuoraPaymentGatewayValue =Application_Settings__c.getInstance(Constants.DIRECT_DEBIT_GATEWAY_NAME).value__c;

            }else if(zuoraPaymentMethodList[0].getValue('Type')==Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE){

                if(zuoraPaymentMethodList[0].getValue('CreditCardCountry')==constants.UNITED_KINGDOM_COUNTRY_NAME_VALUE){

                    //if the payment method is credit card and country is UK , get the UK credit card gateway name
                    ZuoraPaymentGatewayValue= Application_Settings__c.getInstance(Constants.UK_CREDIT_CARD_GATEWAY_NAME).value__c;

                } else {

                    //if the payment method is credit card and country is NOT UK , get the INTERNATIONAL credit card gateway name
                    ZuoraPaymentGatewayValue= Application_Settings__c.getInstance(Constants.INTERNATIONAL_CREDIT_CARD_GATEWAY_NAME).value__c;
                }
            } else if(zuoraPaymentMethodList[0].getValue('Type') == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
                //if the payment method is paypal , get the paypal gateway name
                ZuoraPaymentGatewayValue = Application_Settings__c.getInstance(Constants.PAYPAL_GATEWAY_NAME).Value__c;
            }
        }

        return ZuoraPaymentGatewayValue;
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////End Payment Gateway Helper Functions//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        29/06/2015
    Function    This function is called to set the zuora billing account auto pay and default payment fields while sending to zbilling and a billing account exists
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1            16/01/2016
    ****************************************************************************************/
    public static void setDefaultPaymentMethod(Zuora.zApi zApi,string ZuoraAccountId,string ZuoraPaymentID,boolean SetAutoPay) {

        //get the new payment method's gateway
        string PaymentMethodGatewayValue=Zuora_Utility.getPaymentMethodGatewayValue(zApi,ZuoraPaymentID);

        //specify the object we want to update in our case the account
        Zuora.zObject zAccount = new Zuora.zObject(constants.ZUORA_ZBILLING_ACCOUNT_OBJECT_NAME);

           //set the account id
        zAccount.setValue(constants.ZUORA_ZBILLING_ACCOUNT_ID_FIELD_NAME,ZuoraAccountId); //an existing account

           //set the default payment Id for the billing account
        zAccount.setValue(constants.ZUORA_ZBILLING_ACCOUNT_DEFAULT_PAYMENT_FIELD_NAME, ZuoraPaymentID);

        //set the default payment gateway for the billing account
        zAccount.setValue(constants.ZUORA_ZBILLING_ACCOUNT_PAYMENT_GATEWAY, PaymentMethodGatewayValue);

        //set the auti pay of the billing account
        zAccount.setValue(constants.ZUORA_ZBILLING_ACCOUNT_AUTO_PAY_FIELD_NAME, SetAutoPay);

       //if it is not a unit test class call the zupdate to update the billing account
       if ( !Test.isRunningTest() ) {
              List < Zuora.zApi.SaveResult > results = zApi.zUpdate(new List < Zuora.zObject > {zAccount});
              CheckZuoraResults(results,'setDefaultPaymentMethod');
       }
      }

     /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        25/11/2015
    Function    This function is called to add the outbound product
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1            16/2/2016    //Get Outbound product by excluding all discount rate plans charges and non open offer rate plans
    ****************************************************************************************/
    public static void AddOutboundProduct(Id quoteObjId,string outboundProductName,string outboundPaymentFrequency){

        //1. get the product ID from custom setting
        if(Outbound_Product_Mapping__c.getInstance(outboundProductName)==null){
            throw new TMGUtil.GenericException(Label.Outbound_Product_Mapping_Missing_Error_Message);
            return;
        }

        string productId=Outbound_Product_Mapping__c.getInstance(outboundProductName).SF_Product_ID__c;
        if(string.isempty(productId)){
            throw new TMGUtil.GenericException(Label.Outbound_Product_Mapping_Missing_Error_Message);
            return;
        }

        //2. get the correct rate plan based on the payment frequency for this product
        string ratePlanChargeSoql='select id,name,zqu__Type__c,zqu__Model__c,zqu__ZuoraId__c,zqu__ProductRatePlan__c from zqu__ProductRatePlanCharge__c ';
        ratePlanChargeSoql+='where zqu__Deleted__c=false and IsDeleted=false and zqu__ProductRatePlan__r.zqu__ZProduct__c=\''+productId+'\' and ( not Name like \'%'+Constants.DISCOUNT_RATE_PLAN_NAME+'%\') and ( not Name like \'%'+Constants.EMPTY_DISCOUNT_RATE_PLAN_NAME+'%\') and (zqu__ProductRatePlan__r.name like \'%'+Constants.OPEN_OFFER_RATE_PLAN_VALUE+'%\')';
        if(outboundPaymentFrequency=='a'){
            ratePlanChargeSoql+=' and zqu__RecurringPeriod__c=\'Annual\'';
        }else if(outboundPaymentFrequency=='m'){
            ratePlanChargeSoql+=' and zqu__RecurringPeriod__c=\'Month\'';
        }

        system.debug('########Info: ratePlanChargeSoql: '+ratePlanChargeSoql);
        list<zqu__ProductRatePlanCharge__c> lstRatePlanCharges;

        try{
            lstRatePlanCharges=database.query(ratePlanChargeSoql);
        }catch(exception ex){
            system.debug('Error Occurred to query product rate plan: '+ex);
            throw new TMGUtil.GenericException(Label.Outbound_RatePlan_Query_Error_Message);
            return;
        }

        //3. if quote rate plan charge found get the rate plan id and use it to add the product and rate plan to the quote
        if(lstRatePlanCharges!=null && lstRatePlanCharges.size()>0){

            //if running unit test we can't use the zquoteUtil so I need to insert the Quote Rate Plan manually
            if(test.isRunningTest()){
                for (zqu__ProductRatePlanCharge__c productRatePlanCharge: lstRatePlanCharges) {

                    //insert the quote amendment
                    zqu__QuoteAmendment__c quoteAmendmentObj=new zqu__QuoteAmendment__c();
                    quoteAmendmentObj.zqu__Quote__c=quoteObjId;
                    quoteAmendmentObj.zqu__Status__c='Draft';
                    quoteAmendmentObj.zqu__Type__c='NewProduct';
                    quoteAmendmentObj.zqu__TotalAmount__c=8;
                    insert quoteAmendmentObj;

                    //insert the quoteRatePlanObj
                    zqu__QuoteRatePlan__c quoteRatePlanObj = new zqu__QuoteRatePlan__c();
                    quoteRatePlanObj.Name = 'Open Offer - Monthly';
                    quoteRatePlanObj.zqu__Quote__c = quoteObjId;
                    quoteRatePlanObj.zqu__ProductRatePlanZuoraId__c = productRatePlanCharge.zqu__ZuoraId__c;
                    quoteRatePlanObj.zqu__AmendmentType__c='NewProduct';
                    quoteRatePlanObj.zqu__QuoteProductName__c=productRatePlanCharge.Name;
                    quoteRatePlanObj.zqu__ProductRatePlan__c= productRatePlanCharge.zqu__ProductRatePlan__c;
                    quoteRatePlanObj.zqu__QuoteAmendment__c=quoteAmendmentObj.id;
                    insert quoteRatePlanObj;

                    //insert the quote Rate Plan Charges
                    zqu__QuoteRatePlanCharge__c quoteRatePlanCharge=new zqu__QuoteRatePlanCharge__c();
                    quoteRatePlanCharge.name=productRatePlanCharge.Name+' Subscription';
                    quoteRatePlanCharge.zqu__QuoteRatePlan__c=quoteRatePlanObj.id;
                    quoteRatePlanCharge.zqu__Total__c=8;
                    quoteRatePlanCharge.zqu__Quantity__c=1;
                    quoteRatePlanCharge.zqu__Period__c='Month';
                    quoteRatePlanCharge.zqu__Model__c='Flat Fee Pricing';
                    quoteRatePlanCharge.zqu__ListTotal__c=8;
                    quoteRatePlanCharge.zqu__ListPrice__c=8;
                    quoteRatePlanCharge.zqu__FeeType__c='Flat Fee';
                    quoteRatePlanCharge.zqu__EffectivePrice__c=8;
                    quoteRatePlanCharge.zqu__Currency__c='GBP';
                    insert quoteRatePlanCharge;
                }
                return;
            }else{
                //1. call zuora utility class to create the charge group from the product rate plans Id
                List<zqu.zChargeGroup> newChargeGroups = zqu.zQuoteUtil.getChargeGroups(quoteObjId,new list<id>{lstRatePlanCharges[0].zqu__ProductRatePlan__c});

                //check if there is new charge group ready to be inserted, call the addChargeGroups method from Zuora Utility class
                if(newChargeGroups!=null && newChargeGroups.size()>0){
                    zqu.ZQuoteUtil.addChargeGroups(newChargeGroups);
                }
            }
        }else{
            throw new TMGUtil.GenericException(Label.Outbound_Invalid_Product_Error_Message);
            return;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        22/05/2015
    Function    This function is called to to add a discount based on an offer code to quote
    ******************* Change Log *******************
    Modified by         Change Date
    Sally ElGhoul       17/02/2016 - Add quote offer code record for offers with zero discount
    Gavin Palmer        10/05/2016 - added a rewrite for the product price so that we rely on the offer base price instead
                                     also added a condition in the discounts loop so that it skips any with 54000 which is essentially the base price
    Wiktor Czykin       20/05/2017 - Changed method signature to work with Offer object
    ****************************************************************************************/
    public static void addNewOfferCode(zqu__Quote__c quoteObj, String quoteSubscriptionType, Offer__c offerCodeDetail, List<zqu.zChargeGroup> quoteChargeGroups, String offerType){
        //1. Delete the Discount Chagre Groups that already exist from the Quote. That means the user is changing the offer code value
        List<zqu.zChargeGroup> lstQuoteNotDeletedChargeGroups;

        overwriteProductPriceWithBasePrice(quoteChargeGroups, offerCodeDetail.Base_Price__c);
        //acquisition discounts are only available in new subscription and no other type is available with it
        //when we add an acquisition discount , we delete all other discounts first
        //this will delete either another acquisition discount or a default offer code discount
        //the rule is to have either offer code discount or an acquisition discount
        if(offerType == Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE || offerType == Constants.OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE){
            //this will delete also the quote Offer Code records of the quote rate plan charges that will be deleted
            lstQuoteNotDeletedChargeGroups = deleteDiscountRatePlansByOfferType(quoteObj.Id, 
                                                                                quoteChargeGroups, 
                                                                                new List<String>{Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE,
                                                                                Constants.OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE});
            //delete the quote offer code for default offers that has no discount and not related to quote rate plan charge
            deleteAnnualQuoteOfferCodeRecords(quoteObj);
        }else{
            lstQuoteNotDeletedChargeGroups = quoteChargeGroups;
        }

        //2. Get the Products on the quote
        //We will use these products to query and get the discount rate plan for these products
        Set<id> setQuoteProductIds = getQuoteProducts(quoteObj.Id, lstQuoteNotDeletedChargeGroups);
        if(setQuoteProductIds==null || setQuoteProductIds.size()==0){throw new TMGUtil.GenericException(Constants.OFFER_CODE_ONE_PRODUCT_REQUIRED_ERROR_MESSAGE);}

        //3. get the discunt rate plan of the products
        Set<Id> setProductDiscountRatePlanIds = getProductDiscountRatePlanIds(setQuoteProductIds);
        if(setProductDiscountRatePlanIds==null || setProductDiscountRatePlanIds.size()==0){throw new TMGUtil.GenericException(Constants.OFFER_CODE_NO_DISCOUNT_RATE_PLAN_ERROR_MESSAGE);}

        //Sometimes the call from core API returns more than one discount for the offer so we need to handle this
        if(offerCodeDetail.Discount__c !=null){
            //4. insert the discount rate plan to the product using the offer quote Details
            insertDiscountRatePlans(quoteObj.Id, setProductDiscountRatePlanIds, offerCodeDetail);
            //5.Update the Quote Rate Plan Charge record "Up To How Many Periods" and "Period" to match the values in offerCodeDetail
            //Starting in the Zuora version 6.50, this object is used for New Subscription quotes, as well so only one call is needed now.
            updateQuoteRatePlanChargeRecord(quoteObj.Id, offerCodeDetail, offerType);
        }else{
            insertQuoteOfferCodeForZeroDiscountOffer(quoteObj, offerCodeDetail, offerType);
        }
     }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         10/05/2016
    * Description:  overwrite the price that was set from the product within zuora so that we
    *                can set it from the base price provided from the offer
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    private static void overwriteProductPriceWithBasePrice(List<zqu.zChargeGroup> chargeGroups, Decimal basePrice){
        for(zqu.zChargeGroup chargeGroup : chargeGroups){
            if(chargeGroup.ratePlanName == Constants.DISCOUNT_RATE_PLAN_NAME) continue;

            List<zqu.zCharge> updatedCharges = new List<zqu.zCharge>();

            for(zqu.zCharge zCharge : chargeGroup.zCharges){

                zCharge.EFFECTIVE_PRICE = String.valueOf(basePrice);

                updatedCharges.add(zCharge);
            }
            chargeGroup.zCharges = zqu.zQuoteUtil.calculateChargesOnEffectivePriceChange(updatedCharges);
            zqu.zQuoteUtil.updateChargeGroup(chargeGroup);
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        17/02/2016
    Function    This function is called to insert quote offer code record for offers with zero discount
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static void insertQuoteOfferCodeForZeroDiscountOffer(zqu__Quote__c quoteObj, Offer__c offerCodeDetailsResult, String offerType){
        //if the offer code has zero discounts, insert only the quote offer code record for this offer
        Quote_Offer_Code__c offerCodeNoDiscountObj=OfferCode_Utility.addNewOfferCode(quoteObj.Id, offerCodeDetailsResult, null, offerType);

        if(!String.isEmpty(quoteObj.Subscription_Rate_Plan_Term_Type__c)){
            if(quoteObj.Subscription_Rate_Plan_Term_Type__c.toLowerCase().contains(Constants.PRODUCT_FREQUENCY_ANNUAL)){
                offerCodeNoDiscountObj.Blling_Period__c = Constants.PRODUCT_FREQUENCY_ANNUAL.capitalize();
            }else if(quoteObj.Subscription_Rate_Plan_Term_Type__c.tolowerCase().contains(Constants.PRODUCT_FREQUENCY_MONTHLY)){
                offerCodeNoDiscountObj.Blling_Period__c = Constants.PRODUCT_FREQUENCY_MONTHLY.capitalize();
            }
        }
        offerCodeNoDiscountObj.Discount_Amount__c=0;
        offerCodeNoDiscountObj.Number_of_Periods__c=0;
        insert offerCodeNoDiscountObj;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        21/01/2016
    Function    This function is called to delete the quote offer quote that is not linked to rate plan charge
                this will happen only now to delete the default offer code of annual because they don't have discounts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static void deleteAnnualQuoteOfferCodeRecords(zqu__Quote__c quoteObj){
         //get the quote offer code record without quote rate plan charge
         list<Quote_Offer_Code__c> lstAnnualQuoteOfferCode=[select id from Quote_Offer_Code__c where Quote__c=:quoteObj.id and Quote_Rate_Plan_Charge__c=''];

        //delete these quote offer code
        if(lstAnnualQuoteOfferCode!=null && lstAnnualQuoteOfferCode.size()>0){
            delete lstAnnualQuoteOfferCode;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        22/05/2015
    Function    This function is called to delete the existing discount rate plan from the quote that were added from another offer code earlier
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static List<zqu.zChargeGroup> deleteDiscountRatePlans(Id quoteObjId,List<zqu.zChargeGroup> quoteChargeGroups,set<id> setDeleteQuoteRatePLanChargeIds){
        //if running test we need to delete it
        if(Test.isRunningTest()){
            list<zqu__QuoteCharge__c> lstDelQuoteChagre=[select id from zqu__QuoteCharge__c where zqu__Quote__c=:quoteObjId and zqu__ProductRatePlanName__c=:constants.DISCOUNT_RATE_PLAN_NAME];
            if(lstDelQuoteChagre!=null && lstDelQuoteChagre.size()>0){
                delete lstDelQuoteChagre;
            }
        }

        List<zqu.zChargeGroup> lstQuoteDeleteChargeGroups = new List<zqu.zChargeGroup>();
        List<zqu.zChargeGroup> lstQuoteNotDeletedChargeGroups = new List<zqu.zChargeGroup>();
        //Loop on the chagre group and check the name to GET all the discount charge groups to be deleted
        for(zqu.zChargeGroup chargeGroupObj: quoteChargeGroups){
            //skip the removed products already and don't delete them
            if(chargeGroupObj.groupType!=zqu.zChargeGroup.TYPE_AMENDMENT_REMOVEPRODUCT && chargeGroupObj.groupType!=zqu.zChargeGroup.TYPE_RENEWAL_REMOVEPRODUCT){
                for(zqu.zCharge zChargeObj : chargeGroupObj.zCharges){
                    if(setDeleteQuoteRatePLanChargeIds.contains(zChargeObj.Id)){
                        lstQuoteDeleteChargeGroups.add(chargeGroupObj);
                    }else{
                        lstQuoteNotDeletedChargeGroups.add(chargeGroupObj);
                    }
                }
            }
        }
        //If there any discount charge group found, delete them
        if(lstQuoteDeleteChargeGroups!=null && lstQuoteDeleteChargeGroups.size()>0){
            zqu.ZQuoteUtil.deleteChargeGroups(lstQuoteDeleteChargeGroups);
        }

        return lstQuoteNotDeletedChargeGroups;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        22/05/2015
    Function    This function is called to get the set of product ids on a certain quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static set<id> getQuoteProducts(Id quoteObjId, List<zqu.zChargeGroup> lstQuoteChagreGroups){

        set<string> setRatePlanIds      = new set<string>();
        set<id>     setQuoteProductIds  = new set<id>();

        //lstQuoteChagreGroups will contain the quote charge groups after deleting the discount charge groups in step 1
        //1. Get the list productRatePlanIds from the chagre groups on the quote
        for(zqu.zChargeGroup chargeGroupObj :lstQuoteChagreGroups){
            if(!setRatePlanIds.contains(chargeGroupObj.productRatePlanId) && chargeGroupObj.groupType!=zqu.zChargeGroup.TYPE_AMENDMENT_REMOVEPRODUCT && chargeGroupObj.groupType!=zqu.zChargeGroup.TYPE_RENEWAL_REMOVEPRODUCT){
                setRatePlanIds.add(chargeGroupObj.productRatePlanId);
            }
        }

        //We can't use the zQuoteUtil in unit test classes so I will query the quote charge to get the ratePlan Ids
        if(test.isRunningTest()){
            List<zqu__QuoteCharge__c> lstquoteCharges = [select id,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c from zqu__QuoteCharge__c where zqu__Quote__c=:quoteObjId];
            for(zqu__QuoteCharge__c quoteChargeObj : lstquoteCharges){
                if(!setRatePlanIds.contains(quoteChargeObj.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c)){
                    setRatePlanIds.add(quoteChargeObj.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c);
                }
            }
        }

        //3. Query the Product Rate Plan object to get the product
        List<zqu__ProductRatePlan__c> lstQuoteRatePlans=[select zqu__ZProduct__r.id,id from zqu__ProductRatePlan__c where id in :setRatePlanIds];
        for(zqu__ProductRatePlan__c ratePlanObj : lstQuoteRatePlans){
            if(!setQuoteProductIds.contains(ratePlanObj.zqu__ZProduct__r.Id)){
                setQuoteProductIds.add(ratePlanObj.zqu__ZProduct__r.Id);
            }
        }
        return setQuoteProductIds;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        22/05/2015
    Function    This function is called to get the discount rate plan of the products
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Set<Id> getProductDiscountRatePlanIds(Set<Id> setProductIds){
        Map<Id, zqu__ProductRatePlan__c> mapProductRatePlans= new Map<Id, zqu__ProductRatePlan__c>([select Id from zqu__ProductRatePlan__c where zqu__ZProduct__c in :setProductIds and Name=:Constants.DISCOUNT_RATE_PLAN_NAME and zqu__Deleted__c=false and IsDeleted=false]);
        return mapProductRatePlans.keySet();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        22/05/2015
    Function    This function is called to insert the discount rate plans (chargegroups)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.1         10/2/2016 adding a negative charge discount instead of discount rate plan
    ****************************************************************************************/
    public static void insertDiscountRatePlans(Id quoteObjId, Set<Id> setRatePlansIds, Offer__c offerCodeDetail){
        //if running unit test we can't use the zquoteUtil so I need to insert the quote charge manually
        if(test.isRunningTest()){
            List <zqu__ProductRatePlanCharge__c> productRatePlanCharges = [SELECT Id, Name, zqu__ProductRatePlan__c, zqu__Type__c, zqu__Model__c, zqu__ZuoraId__c FROM zqu__ProductRatePlanCharge__c WHERE zqu__ProductRatePlan__c in : setRatePlansIds];
            List <zqu__QuoteCharge__c> quoteCharges = new List<zqu__QuoteCharge__c> ();
            for (zqu__ProductRatePlanCharge__c productRatePlanCharge: productRatePlanCharges) {
                zqu__QuoteCharge__c quoteCharge = new zqu__QuoteCharge__c();
                quoteCharge.Name = productRatePlanCharge.Name;
                quoteCharge.zqu__ChargeType__c = productRatePlanCharge.zqu__Type__c;
                quoteCharge.zqu__Currency__c = 'GBP';
                quoteCharge.zqu__EffectivePrice__c = 10;
                quoteCharge.zqu__Model__c = productRatePlanCharge.zqu__Model__c;
                quoteCharge.zqu__ProductRatePlanCharge__c = productRatePlanCharge.Id;
                quoteCharge.zqu__ProductRatePlanName__c = 'Discount';
                quoteCharge.zqu__Quote__c = quoteObjId;
                quoteCharge.zqu__Quantity__c = 10;
                quoteCharge.zqu__RatePlanCharge_ZuoraID__c = productRatePlanCharge.zqu__ZuoraId__c;
                quoteCharges.add(quoteCharge);
            }
            if(quoteCharges!=null && quoteCharges.size()>0)
                insert quoteCharges;
            return;
        }

        //Check first that the set of discount rate plans is not empty
        if(setRatePlansIds != null && setRatePlansIds.size()>0){
            //1. call zuora utility class to create the charge group from the discount rate plans Ids
            List<zqu.zChargeGroup> newChargeGroups = zqu.zQuoteUtil.getChargeGroups(quoteObjId, new List<Id>(setRatePlansIds));
            List<zqu.zChargeGroup> newUpdatedChargeGroups = new List<zqu.zChargeGroup>();
                //2. Loop on the charge groups returned from the utility class
            for(zqu.zChargeGroup chargeGourObj : newChargeGroups){
                //this list will be used to add the update zcharge objects to it
                List<zqu.zCharge> updatedCharges = new List<zqu.zCharge>();
                //Loop on the zCharges of each chargeGroup
                for(zqu.zCharge chargeObj : chargeGourObj.zCharges){
                    //Update the effective price from the offercodeDetails
                    //Set the effective price to be negative because we use now the negative charge approach to add discount (flat fee rate plan model) instead
                    //of fixed amount discount
                    chargeObj.EFFECTIVE_PRICE = '-'+String.valueof(offerCodeDetail.Discount__c);
                    //Add the update Zcharge to the update list
                    updatedCharges.add(chargeObj);
                }

                //Call this method from zuora utility class to calculate the chages because the effective price is update
                chargeGourObj.zCharges = zqu.zQuoteUtil.calculateChargesOnEffectivePriceChange(updatedCharges);
                newUpdatedChargeGroups.add(chargeGourObj);
            }

            //check if there is new charge group ready to be inserted, call the addChargeGroups method from Zuora Utility class
            if(newUpdatedChargeGroups!=null && newUpdatedChargeGroups.size()>0){
                zqu.ZQuoteUtil.addChargeGroups(newUpdatedChargeGroups);
            }
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        12/06/2015
    Function    This function is called to update the discount rate plans 'Up to How Many Periods' and the 'billing period'
    ******************* Change Log **********************************************************
    Modified by     Change Date
    ****************************************************************************************/
    public static void updateQuoteRatePlanChargeRecord(Id quoteObjId, Offer__c offerCodeDetail, String offerType){
        //the new offer codes to be added in Salesforce.
        List<Quote_Offer_Code__c> lstNewQuoteOfferCodes = new List<Quote_Offer_Code__c>();
        //Because now we are allowing multiple offer codes
        //We need only to update the quote rate plan charge for the new offer we just created
        //the new offer just added won't have a record yet in Salesforce offer code object
        //so, query the offer codes for the quote and before updating make sure that the quote rate plan charge record
        //is not linked to any salesforce offer code records
        List<Quote_Offer_Code__c> lstQuoteOffers = OfferCode_Utility.getAllQuoteOfferCodes(quoteObjId);
        //this set will have the ids of quote rate plan charges linked to the quote offer code records
        Set<String> setOffersRatePlanChargeIds = new Set<String>();
        for(Quote_Offer_Code__c offerCodeObj : lstQuoteOffers){
            if(!setOffersRatePlanChargeIds.contains(offerCodeObj.Quote_Rate_Plan_Charge__c)){
                setOffersRatePlanChargeIds.add(offerCodeObj.Quote_Rate_Plan_Charge__c);
            }
        }

        //get all the discount quote charges for the quote
        List<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanCharges = [select     Id, 
                                                                                zqu__Period__c, 
                                                                                zqu__Upto_How_Many_Periods__c 
                                                                            from zqu__QuoteRatePlanCharge__c 
                                                                            where zqu__QuoteRatePlan__r.zqu__Quote__c = :quoteObjId 
                                                                            and Name = :Constants.DISCOUNT_RATE_PLAN_NAME];

        //loop on the quote chagres and update the values using the offer code details
        for(zqu__QuoteRatePlanCharge__c quoteRateChargeObj : lstQuoteRatePlanCharges){
            //make sure first it is a new record to update the value, if it is the rate plan charge of an existing offer code don't update the values
            if(!setOffersRatePlanChargeIds.contains(quoteRateChargeObj.Id)){
                quoteRateChargeObj.zqu__Period__c = GlobalQueries.replaceOfferFrequencyForApi(offerCodeDetail.Frequency__c);
                quoteRateChargeObj.zqu__Upto_How_Many_Periods__c = offerCodeDetail.Discount_Duration__c;
                //update the end date condition and up to how many period type fields so the up to how many period get synced to zuora successfully in case of flat fee discount charge
                quoteRateChargeObj.zqu__EndDateCondition__c = Constants.DISCOUNT_END_DATE_CONDITION_VALUE;
                quoteRateChargeObj.zqu__Upto_How_Many_Periods_Type__c = Constants.DISCOUNT_UP_TO_HOW_MANY_PERIODS_TYPE_VALUE;
                //create the new salesforce quote offer code object and add it to the list of offer codes that we will insert
                lstNewQuoteOfferCodes.add(OfferCode_Utility.addNewOfferCode(quoteObjId, offerCodeDetail, quoteRateChargeObj.Id, offerType));
            }
        }
        //check is there is one or more quote charges found, update them
        if(lstQuoteRatePlanCharges != null && lstQuoteRatePlanCharges.size() > 0){
            update lstQuoteRatePlanCharges;
        }
        //check if there is a new offer code to insert
        if(lstNewQuoteOfferCodes!=null && lstNewQuoteOfferCodes.size()>0){
            insert lstNewQuoteOfferCodes;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    This function is called to update the cancelled subscription fields
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void UpdateCancelledSubscription(Zuora.zApi zApi,string cancellationReason,string subCancellationReason,string cancellationEffectiveDateTimeString,string cancellationProcessDateTimeString,string ZuoraSubscriptionId) {
        //specify the object we want to update in our case the account
        Zuora.zObject zSubscription = new Zuora.zObject(constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);

           system.debug('Zuora Subscription ID Check: '+ZuoraSubscriptionId);
           //set the account id
        zSubscription.setValue(constants.ZUORA_ZBILLING_SUBSCRIPTION_ID_FIELD_NAME,ZuoraSubscriptionId); //an existing subscription

           //set the cancellation reason field
        zSubscription.setValue(constants.ZUORA_ZBILLING_SUBSCRIPTION_CANCELLATION_REASON_FIELD_NAME, cancellationReason);

        //set the sub cancellation reason field
        zSubscription.setValue(constants.ZUORA_ZBILLING_SUBSCRIPTION_SUB_CANCELLATION_REASON_FIELD_NAME, subCancellationReason);

        //set the subscription cancellation date string
        system.debug('Check cancellationEffectiveDateTimeString: '+cancellationEffectiveDateTimeString);
        zSubscription.setValue(constants.ZUORA_ZBILLING_SUBSCRIPTION_EFFECTIVE_CANCELLATION_FIELD_NAME, cancellationEffectiveDateTimeString);

        //set the subscription process date string
        zSubscription.setValue(constants.ZUORA_ZBILLING_SUBSCRIPTION_PROCESS_CANCELLATION_FIELD_NAME,cancellationProcessDateTimeString);

       //if it is not a unit test class call the zupdate to update the billing account
       if ( !Test.isRunningTest() ) {
              List < Zuora.zApi.SaveResult > results = zApi.zUpdate(new List < Zuora.zObject > {zSubscription});
              CheckZuoraResults(results,'UpdateCancelledSubscription');
       }
      }

    /***************************************************************************************
    Developer   Michal Kwika
    Date        08/09/2015
    Function    this is method to delete single record from Zuora instance
                Warning! we assume that we are already logged to Zuora and
                zApiInstance is  instantiated
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean deleteZuoraRecords(List <String> lZuoraIds, String zuoraObjectName, Zuora.zApi zApiInstance) {
        try{
            List<Zuora.zApi.DeleteResult> results =zApiInstance.zdelete(zuoraObjectName, lZuoraIds);
            //check if everything is OK
            for(Zuora.zApi.DeleteResult result : results){
                if(!result.Success){
                    System.debug('### ZuoraUtilities|deleteZuoraRecords result ' + result );
                    return false;
                }
            }
        }catch (Zuora.zAPIException ex) {
            System.debug('### ZuoraUtilities|deleteZuoraRecords exception: ' + ex.getMessage());
            return false;
        }
        return true;
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        08/09/2015
    Function    
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String getFrequencyForOffer(String sSource){
        if(String.isBlank(sSource)) return sSource;

        sSource = sSource.toLowerCase();
        sSource = MAP_OFFER_FREQUENCY.get(sSource);
        if(String.isBlank(sSource)) throw new TelegraphApplicationException('No frequency match found in configuration for the passed offer frequency.');
        
        return sSource;
    }
}