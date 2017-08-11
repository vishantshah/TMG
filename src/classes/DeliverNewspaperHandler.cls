/**
* @author Wiktor Czykin
* @date 22/06/2017
* @description REST apex class to handle requests from Deliver My Newspaper 3rd party
*#############Change Log#############
*Modified by     Change Date
*Wiktor Czykin   12/07/2017 //added sam account creation for new account 
*Wiktor Czykin   20/07/2017 //modified processDelivery() and moved future method to SAMUtil
**/
@RestResource(urlMapping='/DeliverNewspaper/v1/*')
global without sharing class DeliverNewspaperHandler{

    @TestVisible private static final String OPTIN_YES = 'Yes';
    @TestVisible private static final String ACTION_NAME = 'Add Delivery';
    
    private static final String SETTING_NAME = 'Deliver My Newspaper';
    private static final String ENDPOINT = 'DeliverNewspaper';
    private static final String BODY_PARAM = 'body';
    private static final String CONTENT_TYPE = 'Content-Type';
    private static final String CONTENT_JSON = 'application/json';

    @TestVisible private static Boolean bDupeScenario = false;

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/06/2017
    Function - post rest method to add Home Delivery Voucher record
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   12/07/2017  //added sam account creation logic and logging
    Wiktor Czykin   20/07/2017  //changed call to future method
    ****************************************************************************************/
    @HttpPost
    global static void processDelivery(){
        RestContext.response.addHeader(CONTENT_TYPE, CONTENT_JSON);
        
        Map<String, String> mapParams = RestContext.request.params;
        String sPayload = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString():'';
        if(mapParams == null) mapParams = new Map<String, String>();
        mapParams.put(BODY_PARAM, sPayload);

        DeliverNewspaperBean.DeliverNewspaperErrorResponseBean errorResponse = new DeliverNewspaperBean.DeliverNewspaperErrorResponseBean();
        Webservice_Log__c wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_INBOUND, ENDPOINT, ACTION_NAME, mapParams, null, null, null);
        Home_Delivery_Voucher__c hdv;
        String sReturnValue = '';
        String sExceptionMessage = '';
        Integer iStatusCode = 201;
        String sSamError = '';
        Boolean bCreateSAMAccount = false;
        try{
            DeliverNewspaperBean.DeliverNewspaperBeanData dnb = (DeliverNewspaperBean.DeliverNewspaperBeanData) JSON.deserialize(mapParams.get(BODY_PARAM), DeliverNewspaperBean.DeliverNewspaperBeanData.class);
            hdv = new Home_Delivery_Voucher__c(API_Data__c = mapParams.get(BODY_PARAM));

            populateFields(hdv, dnb);
            findAndMapRetailer(hdv);
            findAndMapAccount(hdv);
            
            if(hdv.Account__c == null){
                String sGuid;
                try{
                    sGuid = SAMUtil.checkEmailInSAM(hdv.Email__c);
                    if(String.isBlank(sGuid)){
                        bCreateSAMAccount = true;
                    }
                }catch(Exception e){
                    sSamError += e.getMessage();
                    bCreateSAMAccount = false;
                }

                try{
                    createAndMapNewAccount(hdv, sGuid); 
                }catch(DMLException e){
                    errorResponse.error += String.format(Label.DMN_Main_error_message, new List<String>{dnb.firstName, dnb.lastName})+' ';
                    for(Integer i = 0; i < e.getNumDml(); i++){
                        List<String> lstFieldNames = e.getDmlFieldNames(i);
                        if(lstFieldNames != null && !lstFieldNames.isEmpty()){
                            for(String sField : lstFieldNames){
                                String sFieldMessage = errorResponse.errors.get(sField);
                                if(String.isNotBlank(sFieldMessage)){
                                    sFieldMessage += e.getDmlMessage(i) + ' ';
                                }else{
                                    sFieldMessage = e.getDmlMessage(i) + ' ';
                                }
                                errorResponse.errors.put(sField, sFieldMessage);
                            }
                        }else{
                            errorResponse.error += e.getDmlMessage(i) + ' ';
                        }
                    }
                }
            }

            if(String.isBlank(errorResponse.error)){
                try{
                    insert hdv;
                }catch(DmlException e){
                    for(Integer i = 0; i < e.getNumDml(); i++){
                        errorResponse.error += e.getDmlMessage(i) + ' '; 
                    }
                }
            }

            if(String.isNotBlank(errorResponse.error)){
                throw new TelegraphApplicationException(Label.DMN_DML_processing_error);
            }
        }catch(Exception e){
            sExceptionMessage = e.getMessage()+'; Line number:'+e.getLineNumber()+'; Cause: '+e.getCause()+' '+JSON.serialize(errorResponse);
            if(String.isBlank(errorResponse.error)){
                errorResponse.error = Label.DMN_General_exception_message;
            }
            sReturnValue = JSON.serialize(errorResponse);
            iStatusCode = 400;
        }

        if(String.isBlank(sReturnValue)){
            List<Home_Delivery_Voucher__c> lstRefetchInserted = [SELECT Id, Name FROM Home_Delivery_Voucher__c WHERE Id = :hdv.Id];
            if(!lstRefetchInserted.isEmpty()){
                sReturnValue = JSON.serialize(new DeliverNewspaperBean.DeliverNewspaperSuccessResponseBean(lstRefetchInserted[0].Name));
            }else{
                errorResponse.error = Label.DMN_Partial_success_error;
                sReturnValue = JSON.serialize(errorResponse);
                iStatusCode = 400;
            }
        }
        
        TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, sExceptionMessage + ' ' + sReturnValue + ' '+ sSamError);
        Database.insert(wl, false);
        RestContext.response.statusCode = iStatusCode;
        RestContext.response.responseBody = Blob.valueOf(sReturnValue);

        if(bCreateSAMAccount && hdv != null){
            SAMUtil.createSamAccount(hdv.Account__c);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/06/2017
    Function - helper method to populate simple 1:1 mappings 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static void populateFields(Home_Delivery_Voucher__c hdv, DeliverNewspaperBean.DeliverNewspaperBeanData dnb){
        hdv.RecordTypeId = RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName());
        hdv.First_Name__c = dnb.firstName;
        hdv.Last_Name__c = dnb.lastName;
        hdv.Mailing_Town__c = dnb.town;
        hdv.Mailing_County__c = dnb.county;
        hdv.Mailing_Postal_Code__c = dnb.postcode;
        hdv.Email__c = dnb.email;
        hdv.Subscriber_Number__c = dnb.subscriberId;
        hdv.Phone__c = dnb.phone;

        hdv.Mailing_Address__c = dnb.addressLineOne;
        if(String.isNotBlank(dnb.addressLineTwo)){
            hdv.Mailing_Address__c += '\n'+ dnb.addressLineTwo;
        }
        if(String.isNotBlank(dnb.addressLineThree)){
            hdv.Mailing_Address__c += '\n'+ dnb.addressLineThree;
        }

        if(String.isNotBlank(dnb.optInEmail)){
            if(dnb.optInEmail == OPTIN_YES){
                hdv.Marketing_Preference_Email__c  = true;
            }
        }
        
        if(String.isNotBlank(dnb.optInPhone)){
            if(dnb.optInPhone == OPTIN_YES){
                hdv.Marketing_Preference_Phone__c  = true;
            }
        }
        
        if(String.isNotBlank(dnb.optInPost)){
            if(dnb.optInPost == OPTIN_YES){
                hdv.Marketing_Preference_Post__c  = true;
            }
        }

        if(String.isNotBlank(dnb.optInText)){
            if(dnb.optInText == OPTIN_YES){
                hdv.Marketing_Preference_SMS__c  = true;
            }
        }
       
        if(dnb.deliveryDays != null && !dnb.deliveryDays.isEmpty() && dnb.deliveryDays[0] != null && !dnb.deliveryDays[0].isEmpty()){
            hdv.Delivery_Days__c = String.join(dnb.deliveryDays[0], ';');
        }
        
        hdv.Retailer_Id__c = dnb.retailerId;
        hdv.Retailer_Name__c = dnb.retailerName;
        hdv.Retailer_Phone__c = dnb.retailerPhoneNumber;
        hdv.Retailer_Address__c = dnb.retailerAddressLineOne;
        if(String.isNotBlank(dnb.retailerAddressLineTwo)){
            hdv.Retailer_Address__c += '\n'+dnb.retailerAddressLineTwo;
        }
        hdv.Retailer_Town__c = dnb.retailerTown;
        hdv.Retailer_Post_Code__c = dnb.retailerPostcode;
    }   

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/06/2017
    Function - helper method to find account based on passed in parameters
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static void findAndMapAccount(Home_Delivery_Voucher__c hdv){
        Account selectedAcc; 
        List<Account> lstAccounts;

        //attempt to find by tsNumber
        if(String.isNotBlank(hdv.Subscriber_Number__c)){
            lstAccounts = [SELECT Id FROM Account WHERE Subscriber_Number_static__c = :hdv.Subscriber_Number__c];
            if(!lstAccounts.isEmpty() && lstAccounts.size() == 1){
                selectedAcc = lstAccounts[0];
            }
        }

        //attempt to find by email with extra validation via address fields
        if(selectedAcc == null && String.isNotBlank(hdv.Email__c)){
            Map<String, String> mapFieldsToCompare = new Map<String, String>{   'Mailing_Town__c' => 'PersonMailingCity',
                                                                                'Mailing_County__c' => 'PersonMailingState',
                                                                                'Mailing_Postal_Code__c' => 'PersonMailingPostalCode',
                                                                                'Mailing_Address__c' => 'PersonMailingStreet'
            };
            String sEmail = hdv.Email__c;
            lstAccounts = Database.query('SELECT Id, '+ String.join(mapFieldsToCompare.values(), ',') +' FROM Account WHERE PersonEmail = :sEmail');
            if(lstAccounts.size() == 1 && !bDupeScenario){
                selectedAcc = lstAccounts[0];
            }else if(lstAccounts.size() > 1 || (lstAccounts.size() == 1 && bDupeScenario)){
                Map<Id, Account> mapAccounts = new Map<Id, Account>(lstAccounts);
                Id topId;
                Integer iHighestNumber = 0;
                for(Account acc : lstAccounts){
                    Integer iMatches = 0;
                    for(String sFieldKey : mapFieldsToCompare.keySet()){
                        if(acc.get(mapFieldsToCompare.get(sFieldKey)) == hdv.get(sFieldKey)){
                            iMatches++;
                        }
                    }
                    if(topId == null || iHighestNumber<iMatches){
                        iHighestNumber = iMatches;
                        topId = acc.Id;
                    }
                }
                selectedAcc = mapAccounts.get(topId);
            }
        }
        if(selectedAcc != null){
            hdv.Account__c = selectedAcc.Id;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/06/2017
    Function - helper method to create new account when existing one could not be found
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   12/07/2017  //added setting of guid
    ****************************************************************************************/
    private static void createAndMapNewAccount(Home_Delivery_Voucher__c hdv, String sGuid){
        Account acc = new Account(
            RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME, Account.class.getName()),
            FirstName = hdv.First_Name__c,
            LastName = hdv.Last_Name__c,
            PersonMailingCity = hdv.Mailing_Town__c,
            PersonMailingState = hdv.Mailing_County__c,
            PersonMailingPostalCode = hdv.Mailing_Postal_Code__c,
            PersonMailingStreet = hdv.Mailing_Address__c,
            PersonMailingCountry = Constants.COUNTRY_CODE_GB,
            PersonEmail = hdv.Email__c,
            PersonHomePhone = hdv.Phone__c,
            Guid__c = sGuid
        );

        if(hdv.Marketing_Preference_Email__c){
            acc.TMG_Promo_Email__c = 1;
        }
        if(hdv.Marketing_Preference_Phone__c){
            acc.TMG_Promo_Phone__c = 1;
        }
        if(hdv.Marketing_Preference_Post__c){
            acc.TMG_Promo_Post__c = 1;
        }
        if(hdv.Marketing_Preference_SMS__c){
            acc.TMG_Promo_SMS__c = 1;
        }

        insert acc;
        hdv.Account__c = acc.Id;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/06/2017
    Function - helper method to create new account when existing one could not be found
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static void findAndMapRetailer(Home_Delivery_Voucher__c hdv){
        if(String.isBlank(hdv.Retailer_Id__c)) return;

        List<Account> lstAccounts = [SELECT Id FROM Account WHERE URN__c = :hdv.Retailer_ID__c];
        if(!lstAccounts.isEmpty()){
            hdv.Retailer__c = lstAccounts[0].Id;
        }      
    }

    
}