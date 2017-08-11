/**
* Author:       Sally ElGhoul (Tquila)
* Date:         27/04/2015
* Description:  A utility class for Core API callouts
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      17/12/2016
* Michal Kwika      11/01/2016
* Michal Kwika      04/02/2016 - added double encoding custom setting
* Wiktor Czykin     22/02/2016 - modified object event sending method (added logging), added bulk object event sending method, minor clean-up across the file
* Sally ElGhoul        31/03/2016 - Adding Webservice logging
* Pawel Chrzanowski 28/04/2016 - added putOffer(), sendUpgrade(), GetOffersByProductAndFrequency()
* Gavin Palmer      21/06/2016 - extend BulkLoggerCommon and modify getNumOfEmailsInSAM() to allow bulk webservice insert
* Wiktor Czykin     20/03/2017 - modified so that it still works when uniwue email is enabled for Accounts
**/
global class CoreAPICalloutUtility extends BulkLoggerCommon{

    private static final String POST = 'POST';
    private static final String GET = 'GET';
    private static final String PUT = 'PUT';
    private static final String EVENT_ENDPOINT;
    private static final String UPGRADE_ENDPOINT;
    private static final String PUT_OFFER_ENDPOINT;

    static{
        Application_Settings__c eventEndPoint = Application_Settings__c.getInstance(Constants.CORE_API_EVENT_END_POINT_NAME);
        if(eventEndPoint == null || String.isBlank(eventEndPoint.Value__c)) throw new TelegraphApplicationException(Label.Core_API_Event_endpoint_error);
        EVENT_ENDPOINT = eventEndPoint.Value__c;

        Application_Settings__c upgradeEndPoint = Application_Settings__c.getInstance(Constants.CORE_API_UPGRADE_END_POINT_NAME);
        if(upgradeEndPoint == null || String.isBlank(upgradeEndPoint.Value__c)) throw new TelegraphApplicationException(Label.Core_API_Upgrade_endpoint_error);
        UPGRADE_ENDPOINT = upgradeEndPoint.Value__c;

        Application_Settings__c putOfferEndPoint = Application_Settings__c.getInstance(Constants.CORE_API_PUT_OFFER_END_POINT_NAME);
        if(putOfferEndPoint == null || String.isBlank(putOfferEndPoint.Value__c)) throw new TelegraphApplicationException(Label.Core_API_Put_Offer_endpoint_error);
        PUT_OFFER_ENDPOINT = putOfferEndPoint.Value__c;
    }

    /**
    * @author Gavin Palmer
    * @date 22/06/2016
    * @description call the extended classes constructor
    *#############Change Log#############
    *Modified by    Version     Change Date
    **/
    public CoreAPICalloutUtility(){
        super(CoreAPICalloutUtility.class.getName());
    }

    /***************************************************************************************
    Developer   Michal Kwika
    Date        17/12/2016
    Function    Call Core API - event callout that handles single EventCallOutWrapper
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         22/02/2016  //added logging
    ****************************************************************************************/
    @future(callout=true)
    public static void SendObjectEvent(String eventName, String objectName, String idValue) {
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        WebService_Log__c wl;
        try{
            //Define the endpoint
            String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_EVENT_END_POINT_NAME).Value__c;
            req.setEndpoint(endPointValue);
            req.setMethod(POST);
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);

            //define the body
            CoreApiResources.EventCallOutWrapper eventCalloutWrapperObj = new CoreApiResources.EventCallOutWrapper(eventName, objectName, idValue);

            String sEventToLog = String.format(Constants.LOG_COREAPI_OBJECT_EVENT, new List<String>{objectName, eventName});
            wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, EVENT_ENDPOINT, sEventToLog, eventCalloutWrapperObj, null, null, null);

            req.setBody(JSON.serialize(eventCalloutWrapperObj));
            res = http.send(req);

            TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, res.getStatusCode());
        }catch(Exception e){
            TMGUtil.populateExtraDetailsOnWebServiceRequestSerialized(wl, e.getMessage());
        }
        TMGUtil.logWebServiceRequestSerialized(wl);
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        19/02/2015
    Function    Call Core API - event callout that handles array of EventCallOutWrapper-s -> bulk requests
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         31/03/2017  //changed order of execution so that wlog is never null
    ****************************************************************************************/
    @future(callout=true)
    public static void sendBulkEvents(String sEventName, String sObjectName, Set<Id> setAccountIds){
        if(String.isBlank(sEventName) || String.isBlank(sObjectName) || setAccountIds == null || setAccountIds.isEmpty()) return;

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        WebService_Log__c wl;
        try{
            List<CoreApiResources.EventCallOutWrapper> lstDataToSend = new List<CoreApiResources.EventCallOutWrapper>();
            for(Id recordId : setAccountIds){
                lstDataToSend.add(new CoreApiResources.EventCallOutWrapper(sEventName, sObjectName, recordId+''));
            }
            String sEventToLog = String.format(Constants.LOG_COREAPI_OBJECT_EVENT, new List<String>{sObjectName, sEventName});
            wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, EVENT_ENDPOINT, sEventToLog, lstDataToSend, null, null, null);

            req.setEndpoint(EVENT_ENDPOINT);
            req.setMethod(POST);
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);
            if(!lstDataToSend.isEmpty()){
                req.setBody(JSON.serialize(lstDataToSend));
                res = http.send(req);
                TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, res.getStatusCode());
            }
        }catch(Exception e){
            TMGUtil.populateExtraDetailsOnWebServiceRequestSerialized(wl, e.getMessage());
        }
        TMGUtil.logWebServiceRequestSerialized(wl);
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        28/04/2016
    Function    Call Core API - Upgrade callout
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String sendUpgrade(String subscriptionId, String offerCode, String effectiveDate, String priceChangeNumber){
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        WebService_Log__c wl;
        try{
            //endpoint
            String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_UPGRADE_END_POINT_NAME).Value__c;
            endPointValue = String.format(endPointValue, new List<String>{subscriptionId});

            //request
            req.setEndpoint(endPointValue);
            req.setMethod(POST);
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);
            System.debug('### CoreAPICalloutUtility.sendUpgrade -> HttpRequest: ' + req);

            //request body
            CoreApiResources.UpgradeCallOutWrapper upgradeCallOutWrapperObj = new CoreApiResources.UpgradeCallOutWrapper(offerCode, effectiveDate, priceChangeNumber);
            System.debug('### CoreAPICalloutUtility.sendUpgrade -> upgradeCallOutWrapperObj: ' + upgradeCallOutWrapperObj);
            req.setBody(JSON.serialize(upgradeCallOutWrapperObj));

            //webservice log
            String sEventToLog = String.format(Constants.LOG_COREAPI_UPGRADE, new List<String>{offerCode, effectiveDate, priceChangeNumber});
            wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, UPGRADE_ENDPOINT, sEventToLog, upgradeCallOutWrapperObj, null, null, null);

            //send the request
            res = http.send(req);
            TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, res.getStatusCode());
        }catch(Exception e){
            System.debug('### CoreAPICalloutUtility.sendUpgrade -> Exception: ' + e.getMessage());
            TMGUtil.populateExtraDetailsOnWebServiceRequestSerialized(wl, e.getMessage());
        }
        TMGUtil.logWebServiceRequestSerialized(wl);

        if(res.getStatusCode() == 200 || res.getStatusCode() == 201){
            System.debug('### CoreAPICalloutUtility.sendUpgrade -> Success: ' + res.toString());
            return Label.Upgrade_Subscription_Offer_Success;
        }else{
            System.debug('### CoreAPICalloutUtility.sendUpgrade -> Error: ' + res.getBody());
            return Label.Upgrade_Subscription_Offer_Fail;
        }
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        28/04/2016
    Function    Call Core API - Put Offer callout
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String putOffer(String subscriptionId, String offerCode, String effectiveDate, String priceChangeNumber){
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        WebService_Log__c wl;
        try{
            //endpoint
            String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_PUT_OFFER_END_POINT_NAME).Value__c;
            endPointValue = String.format(endPointValue, new List<String>{subscriptionId});

            //request
            req.setEndpoint(endPointValue);
            req.setMethod(PUT);
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);
            System.debug('### CoreAPICalloutUtility.putOffer -> HttpRequest: ' + req);

            //request body
            CoreApiResources.PutOfferCallOutWrapper putOfferCallOutWrapperObj = new CoreApiResources.PutOfferCallOutWrapper(offerCode, effectiveDate, priceChangeNumber);
            System.debug('### CoreAPICalloutUtility.putOffer -> putOfferCallOutWrapperObj: ' + putOfferCallOutWrapperObj);
            req.setBody(JSON.serialize(putOfferCallOutWrapperObj));

            //webservice log
            String sEventToLog = String.format(Constants.LOG_COREAPI_PUT_OFFER, new List<String>{offerCode, effectiveDate, priceChangeNumber});
            wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, PUT_OFFER_ENDPOINT, sEventToLog, putOfferCallOutWrapperObj, null, null, null);

            //send the request
            res = http.send(req);
            TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, res.getStatusCode());
        }catch(Exception e){
            System.debug('### CoreAPICalloutUtility.putOffer -> Exception: ' + e.getMessage());
            TMGUtil.populateExtraDetailsOnWebServiceRequestSerialized(wl, e.getMessage());
        }
        TMGUtil.logWebServiceRequestSerialized(wl);

        if(res.getStatusCode() == 200){
            System.debug('### CoreAPICalloutUtility.putOffer -> Success: ' + res.toString());
            return Label.Put_Offer_Success;
        }else{
            System.debug('### CoreAPICalloutUtility.putOffer -> Error: ' + res.getBody());
            return Label.Put_Offer_Fail;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        06/05/2015
    Function    Call Core API to Reset Password
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1            31/03/2016 - Adding Webservice logging
    ****************************************************************************************/
    webservice static String resetPassword(String emailValue) {
        try {
            //Prepare the Endpoint to be called
            string endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_RESET_PASSWORD_END_POINT_NAME).value__c;
            string fullEndPointValue = string.format(endPointValue, new list<string> {emailValue});

            WebService_Log__c webserviceLogObj;

            //Call Sam Endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(fullEndPointValue);
            system.debug('Check Full EndPoint Value: ' + fullEndPointValue);
            req.setMethod(GET);

            webserviceLogObj = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, fullEndPointValue, Constants.LOG_RESET_PASSWORD, emailValue, null, null, null);

            //set the headers
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);

            Http http = new Http();
            HTTPResponse res = http.send(req);

            TMGUtil.populateResponseOnWebServiceRequestSerialized(webserviceLogObj, res.getStatusCode());
            TMGUtil.logWebServiceRequestSerialized(webserviceLogObj);

            //Access the body for the result
            //check 204 or 404
            if (res.getStatusCode() == 204) { //Success
                return Label.Reset_Password_Success_Message;
            } else if (res.getStatusCode() == 404) { //Failure 404
                CoreApiResources.ResetPasswordResponseWrapper responseWrapper = (CoreApiResources.ResetPasswordResponseWrapper) System.JSON.deserialize(res.getBody(), CoreApiResources.ResetPasswordResponseWrapper.class);
                system.debug('Error HTTP_CODE: ' + responseWrapper.http_Code + ' , Message: ' + responseWrapper.message + ' ,internal_error_code: ' + responseWrapper.internal_error_code + ' , details_url: ' + responseWrapper.details_url);
                return Label.Reset_Password_Error_Message;
            } else {
                return Label.Reset_Password_Error_Message;
            }

        } catch (Exception ex) {system.debug('Error occured to reset Sam Password password (CoreAPICalloutUtility class, function ResetPassword): ' + ex.getMessage() + ' Line Number : ' + ex.getLineNumber()); return Label.Reset_Password_Error_Message;}

        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        18/05/2015
    Function    Call Core API to Get The offer Code Details
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1            31/03/2016 - Adding Webservice logging
    ****************************************************************************************/
    webservice static CoreApiResources.OfferCodeDetails getOfferCode(String offerCodeValue) {
        try {
            WebService_Log__c webserviceLogObj;

            //Prepare the Endpoint to be called
            String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_GET_OFFER_DETAILS).Value__c;
            String fullEndPointValue = String.format(endPointValue, new List<String> {offerCodeValue});

            //Call Get Offer Code EndPoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(fullEndPointValue);
            req.setMethod(GET);
            //set the headers
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            req.setHeader(Constants.GET_OFFER_CODE_ACCEPT_KEY_HEADER, Constants.GET_OFFER_CODE_ACCEPT_VALUE_HEADER);

            webserviceLogObj = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, fullEndPointValue, Constants.LOG_GET_OFFER_CODE_DETAILS, offerCodeValue, null, null, null);

            //Send the request
            Http http = new Http();
            HTTPResponse res = http.send(req);

            TMGUtil.populateResponseOnWebServiceRequestSerialized(webserviceLogObj, res.getStatusCode());

            //Access the body for the result
            //check 200 means success
            if (res.getStatusCode() == 200) { //Success
                TMGUtil.populateExtraDetailsOnWebServiceRequestSerialized(webserviceLogObj,res.getBody());
                TMGUtil.logWebServiceRequestSerialized(webserviceLogObj);

                //deserialize the response body to get the offer code details
                CoreApiResources.OfferCodeDetails offerCodeResponseWrapper = (CoreApiResources.OfferCodeDetails) System.JSON.deserialize(res.getBody(), CoreApiResources.OfferCodeDetails.class);
                System.debug('CoreAPICalloutUtility offerCodeResponseWrapper:' + offerCodeResponseWrapper);
                return offerCodeResponseWrapper;
            } else {

                TMGUtil.logWebServiceRequestSerialized(webserviceLogObj);
                return null;
            }

        } catch (Exception ex) {system.debug('Error occured to Get Offer Code Details (CoreAPICalloutUtility class, function GetOfferCode): ' + ex.getMessage() + ' Line Number : ' + ex.getLineNumber()); return null;}
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/11/2015
    Function    Call Core API to Get All Offer Code Details
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    webservice static CoreApiResources.CoreApiOffers getAllOfferCodes() {
        try {
            //Prepare the Endpoint to be called
            String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_GET_ALL_OFFERS).value__c;

            //Call Get Offer Code EndPoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointValue);
            req.setMethod(GET);

            //set the headers
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            req.setHeader(Constants.GET_OFFER_CODE_ACCEPT_KEY_HEADER, Constants.GET_OFFER_CODE_ACCEPT_VALUE_HEADER);

            //Send the request
            Http http = new Http();
            HTTPResponse res = http.send(req);

            //Access the body for the result
            //check 200 means success
            if (res.getStatusCode() == 200) { //Success
                //deserialize the response body to get the offer code details
                CoreApiResources.CoreApiOffers offerCodesResponseWrapper = (CoreApiResources.CoreApiOffers) System.JSON.deserialize(res.getBody(), CoreApiResources.CoreApiOffers.class);
                System.debug('check offerCodeResponseWrapper: ' + offerCodesResponseWrapper);
                return offerCodesResponseWrapper;
            } else {
                return null;
            }

        } catch (Exception ex) {system.debug('Error occured to Get All Offer Codes (CoreAPICalloutUtility class, function GetAllOfferCodes): ' + ex.getMessage() + ' Line Number : ' + ex.getLineNumber()); return null;}
        return null;
    }

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        28/04/2016
    Function    Call Core API to get Offers filtered by Product and Frequency
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    webservice static CoreApiResources.CoreApiOffersByProductAndFrequency getOffersByProductAndFrequency(String productNameValue, String frequencyValue){
        try{
            //endpoint
            String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_GET_OFFERS_BY_PRODUCT_AND_FREQUENCY).value__c;
            String fullEndPointValue = String.format(endPointValue, new List<String>{productNameValue, frequencyValue});

            //request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(fullEndPointValue);
            req.setMethod(GET);
            req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
            System.debug('### CoreAPICalloutUtility.GetOffersByProductAndFrequency -> HttpRequest: ' + req);

            //send the request
            Http http = new Http();
            HTTPResponse res = http.send(req);

            //response
            if(res.getStatusCode() == 200){
                System.debug('### CoreAPICalloutUtility.GetOffersByProductAndFrequency -> Success: ' + res.toString());
                CoreApiResources.CoreApiOffersByProductAndFrequency offersResponseWrapper = (CoreApiResources.CoreApiOffersByProductAndFrequency) System.JSON.deserialize(res.getBody(), CoreApiResources.CoreApiOffersByProductAndFrequency.class);
                return offersResponseWrapper;
            }else{
                System.debug('### CoreAPICalloutUtility.GetOffersByProductAndFrequency -> Error: ' + res.getStatusCode());
                return null;
            }
        }catch(Exception e){
            System.debug('### CoreAPICalloutUtility.GetOffersByProductAndFrequency -> Exception: ' + e.getMessage());
            return null;
        }
        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        05/08/2015
    Function    this function validates email in SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         17/11/2015
    Michal Kwika        1.2         28/01/2016
    Michal Kwika        1.3         04/02/2016
    Sally ElGhoul       1.4         31/03/2016 - Adding Webservice logging
    Gavin Palmer        1.5         21/06/2016 - added a bulk logging functionality
    ****************************************************************************************/
    public Map<Integer, String> getNumOfEmailsInSAM(String strEmailToCheck) {
        WebService_Log__c webserviceLogObj;

        //set variable to zero
        Map <Integer, String> mResponseWithId = new Map <Integer, String>();
        //let's assume that there is an error
        mResponseWithId.put(-1, Constants.DIAGNOSTICS_EXTRACT_STATUS_ERROR);
        Integer emailCounterSAM = -1;
        //set http variables
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_SAM_USER_SEARCH_BY_EMAIL).value__c;
        System.debug('### Email value: ' + strEmailToCheck);
        //if there is a plus sing encode it twice - Identity is not doing it for us for this character
        Boolean isDoubleEncoding=false;
        if(Application_Settings__c.getInstance(Constants.CORE_API_SAM_DOUBLE_ENCODING).value__c != null){
            isDoubleEncoding = Boolean.valueOf(Application_Settings__c.getInstance(Constants.CORE_API_SAM_DOUBLE_ENCODING).value__c);
        }
        if(isDoubleEncoding){
            strEmailToCheck = EncodingUtil.urlEncode(EncodingUtil.urlEncode(strEmailToCheck, 'UTF-8'), 'UTF-8');
        }
        endPointValue += '?email=' + strEmailToCheck;
        req.setEndpoint(endPointValue);

        webserviceLogObj = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, endPointValue, Constants.LOG_GET_NUMBER_OF_EMAILS_IN_SAM, strEmailToCheck, null, null, null);

        //define the method type
        req.setMethod(GET);
        req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
        req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);

        //set the headers
        req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);
        System.debug('### SAM email search HttpRequest |' + req.getBody());
        System.debug('### SAM email search HttpRequest 2|' + req);

        res = http.send(req);

        System.debug('### SAM email search response |' + res.getBody());

        TMGUtil.populateResponseOnWebServiceRequestSerialized(webserviceLogObj, res.getStatusCode());

        if(this.bUseBulkLogging){
            this.addLogToBuffer(webserviceLogObj);
        }else{
            TMGUtil.logWebServiceRequestSerialized(webserviceLogObj);
        }

        //Access the body for the result
        //check 200 means success
        if (res.getStatusCode() == 200) {
            //Parse response
            JSONParser parser = JSON.createParser(res.getBody());
            mResponseWithId.clear();
            Integer i = 0;
            while (parser.nextToken() != null) {
                //if current token is a field name
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    String fieldName = parser.getText();
                    //move to token after the field name
                    parser.nextToken();
                    if (fieldName == 'id') {
                        mResponseWithId.put(i, parser.getText());
                        i++;
                    }
                    if (fieldName == 'totalResults') {
                        emailCounterSAM = parser.getIntegerValue();
                    }
                }
            }
        }

        System.debug('### JSONParser EMAIl counterEmail: ' + mResponseWithId);
        return mResponseWithId;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        16/11/2015
    Function    this function is getting profile based on SAMId
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.4         01/04/2016 - Adding Webservice logging
    Gavin Palmer        1.5         22/06/2016 - added bulk logging functionality
    ****************************************************************************************/
    public Account getProfileFromSAM(String samAccountId) {

        WebService_Log__c webserviceLogObj;

        //create Salesforce account object without inserting
        Account samAcc = new Account();
        //set http variables
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        //Prepare the Endpoint to be called
        String endPointValue = Application_Settings__c.getInstance(Constants.CORE_API_SAM_USER_GET_PROFILE_BY_ID).value__c;
        String fullEndPointValue = string.format(endPointValue, new list<string> {samAccountId});

        //Call Sam Endpoint
        req.setEndpoint(fullEndPointValue);
        system.debug('### Check Full EndPoint Value: ' + fullEndPointValue);

        webserviceLogObj = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, fullEndPointValue, Constants.LOG_GET_PROFILE_FROM_SAM, samAccountId, null, null, null);

        //define the method type
        req.setMethod(GET);
        req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
        req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);

        //set the headers
        req.setHeader(Constants.CORE_API_CONTENT_TYPE_KEY_VALUE, Constants.CORE_API_JSON_CONTENT_TYPE_VALUE);
        res = http.send(req);

        System.debug('### SAM status code of response ' + res.getStatusCode());
        System.debug('### SAM profile get response |' + res.getBody());

        TMGUtil.populateResponseOnWebServiceRequestSerialized(webserviceLogObj, res.getStatusCode());

        if(this.bUseBulkLogging){
            this.addLogToBuffer(webserviceLogObj);
        }else{
            TMGUtil.logWebServiceRequestSerialized(webserviceLogObj);
        }

        //Access the body for the result
        //check 200 means success
        if (res.getStatusCode() == 200) {
            //Parse response
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    String fieldName = parser.getText();
                    //move to token after the field name
                    parser.nextToken();
                    fillAccountDataBasedOnSAMfield(samAcc, fieldName, parser);
                }
            }
        }

        return samAcc;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        16/11/2015
    Function    this function is used to create correct Account based on SAM response
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         11/01/2016
    Michal Kwika        1.2         26/01/2016
    ****************************************************************************************/
    public static Account fillAccountDataBasedOnSAMfield(Account accountToFilled, String fieldName, JSONParser parser) {
        //try to get set of data
        if (fieldName.equalsIgnoreCase('id')) {
            //accountToFilled.Guid__c = parser.getText();
        }
        if (fieldName.equalsIgnoreCase('subscriptionParams')) {
            System.debug('@@@ subscriptionParams ' + parser.getText());
        }
        if (fieldName.equalsIgnoreCase('email')) {
            accountToFilled.PersonEmail = parser.getText();
        }
        if (fieldName.equalsIgnoreCase('firstName')) {
            accountToFilled.Firstname = parser.getText();
        }
        if (fieldName.equalsIgnoreCase('lastName')) {
            accountToFilled.LastName = parser.getText();
        }
        if (fieldName.equalsIgnoreCase('title')) {
            String samTitle = parser.getText();
            if (checkIfSalutation(samTitle)) {
                accountToFilled.Salutation = samTitle;
            } else {
                accountToFilled.Title__c = samTitle;
            }

        }
        if (fieldName.equalsIgnoreCase('profileStatus')) {
            accountToFilled.Replatform_Digital_Status__c = parser.getText();
        }
        if (fieldName.equalsIgnoreCase('phoneNumber')) {
            String phone = parser.getText();
            if (phone.contains('null')) {
                accountToFilled.PersonMobilePhone = '';
            } else {
                accountToFilled.PersonMobilePhone = parser.getText();
            }

        }
        //address section
        if (fieldName.equalsIgnoreCase('addressLine1')) {
            String tempText=parser.getText();
            if (tempText.contains('null')) {
                accountToFilled.PersonMailingStreet = '';
            }
            else {
                accountToFilled.PersonMailingStreet = tempText;
            }
        }

        if (fieldName.equalsIgnoreCase('addressLine2')) {
            String tempText=parser.getText();
            if (tempText.contains('null') && String.isBlank(accountToFilled.PersonMailingStreet)) {
                accountToFilled.PersonMailingStreet = '';
            }
            else if(!tempText.contains('null') && String.isNotEmpty(accountToFilled.PersonMailingStreet)){
                accountToFilled.PersonMailingStreet += ' ' + tempText;
            }
            else if(tempText.contains('null') && String.isNotBlank(accountToFilled.PersonMailingStreet)){
               //do nothing
            }
            else {
                accountToFilled.PersonMailingStreet = tempText;
            }
        }

        if (fieldName.equalsIgnoreCase('city')) {
            String tempText=parser.getText();
            if (tempText.contains('null')) {
                accountToFilled.PersonMailingCity = '';
            }
            else {
                accountToFilled.PersonMailingCity = tempText;
            }

        }

        if (fieldName.equalsIgnoreCase('county')) {
            String tempText=parser.getText();
            if (tempText.contains('null')) {
                accountToFilled.PersonMailingState = '';
            }
            else {
                accountToFilled.PersonMailingState = tempText;
            }
        }

        if (fieldName.equalsIgnoreCase('postCode')) {
            String tempText=parser.getText();
            if (tempText.contains('null')) {
                accountToFilled.PersonMailingPostalCode = '';
            }
            else {
                accountToFilled.PersonMailingPostalCode = tempText;
            }
        }

        if (fieldName.equalsIgnoreCase('country')) {
            String tempText=parser.getText();
            if (tempText.contains('null')) {
                accountToFilled.PersonMailingCountry = '';
            }
            else {
                accountToFilled.PersonMailingCountry = tempText;
            }
        }

        return accountToFilled;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/11/2015
    Function    this function is used to check if string is part of account salutation
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean checkIfSalutation(String sTitle) {
        List<SelectOption> statusOptions = new List<SelectOption>();
        Schema.DescribeFieldResult accFieldDescription = Account.Salutation.getDescribe();

        for (Schema.Picklistentry picklistEntry : accFieldDescription.getPicklistValues()) {
            if (sTitle == pickListEntry.getValue()) {
                return true;
            }
        }
        return false;
    }

    /************************************************************************************
    Method Name  : getIdentity
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Method to return IdentityWrapper based jsonMap which can have variety of identity requests
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public IdentityWrapper getIdentity(Map<String, Object> jsonMap, Map<String, String> headerMap){

        WebService_Log__c webserviceLogObj;
        HttpRequest req = new HttpRequest();
        Http http       = new Http();
        String endPoint = Application_Settings__c.getinstance(Constants.IDENTITY_TOKEN_ENDPOINT).Value__c;
        String body     = JSONUtility.getJSONString(jsonMap);
        this.bUseBulkLogging = true;
        req.setMethod(GET); 
        
        for (String key : headerMap.keySet()){
            req.setHeader(key, headerMap.get(key));
        }
        
        req.setBody(body);
        req.setEndpoint(endpoint);
        
        webserviceLogObj = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, endpoint, null, jsonmap, null, null, null);
        
        HttpResponse response = http.send(req);
        
        TMGUtil.populateResponseOnWebServiceRequestSerialized(webserviceLogObj, response.getStatusCode());

        if(this.bUseBulkLogging){
            this.addLogToBuffer(webserviceLogObj);
        }else{
            TMGUtil.logWebServiceRequestSerialized(webserviceLogObj);
        }
        
        IdentityWrapper idWrapper;
        
        if (response.getStatusCode() == 201){
            idWrapper = (IdentityWrapper)System.JSON.deserialize(response.getBody(), IdentityWrapper.Class);
        } else {
            throw new TelegraphApplicationException(response.getStatus() + ' ' + response.getBody());
        }

        return idWrapper;
    }
}