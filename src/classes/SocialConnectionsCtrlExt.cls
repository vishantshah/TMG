/************************************************************************************
Class Name   : SocialConnectionsCtrlExt
Author       : Mantas Grigaliunas
Created Date : 20/09/2016
Function     : Controller extension class for visualforce page 'SocialConnections' which is build get social accounts link from 
               the commerce server and ability to remove the links by sending the request to server
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public with sharing class SocialConnectionsCtrlExt {

    public String selectedNetwork { get; set; }
    public Map<String, SocialProfile> mapSocialNetwork { get; set; }

    private String accountId;
    private static final String  GET        = 'GET';
    private static final String  DEL        = 'DELETE';
    @TestVisible private static final Integer OK            = 200;
    @TestVisible private static final Integer NOT_FOUND     = 404;
    @TestVisible private static final Integer UNAUTHORISED  = 401;
    @TestVisible private static final Integer GONE          = 410;
    @TestVisible private String requestLabel;  // Unique label corresponding to the continuation
    @TestVisible private HttpResponse testResponse;
    @TestVisible private String result;

    /************************************************************************************
    Method Name  : SocialConnectionsCtrlExt (Constructor)
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public SocialConnectionsCtrlExt(ApexPages.StandardController stdController) {
        Account account = (Account)stdController.getRecord();
        accountId = account.Id;
    }
    
    /************************************************************************************
    Method Name  : initialize
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Function     : Method to return the map of the social accounts from commerce server using SF Continuation
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public Object initialize() {

        //get endpoint
        String endpoint = getEndpointSetting(Constants.SOCIAL_REGISTRATION_GET_END_POINT);
        if(endpoint == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                    String.format(Label.Social_Connections_Custom_Setting_Missing, new List<String>{Constants.SOCIAL_REGISTRATION_GET_END_POINT})));
            return null;
        }
        endpoint = String.format(endpoint, new List<String>{accountId});

        // Create continuation with a timeout
        Continuation con = new Continuation(40);
        // Set callback method
        con.continuationMethod = 'processGetResponse';
      
        // Create callout request
        HttpRequest req = new HttpRequest();
        req.setMethod(GET);
        req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
        req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
        req.setEndpoint(endpoint);

        // Add callout request to continuation
        this.requestLabel = con.addHttpRequest(req);
        return con;
    }
    
    /************************************************************************************
    Method Name  : processGetResponse
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Function     : Process the response from the server
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public Object processGetResponse() {   
        HttpResponse response = Continuation.getResponse(this.requestLabel);
        mapSocialNetwork = new Map<String, SocialProfile>();
        result = response.getBody();
        Integer statusCode = response.getStatusCode();

        if(statusCode == OK){
            mapSocialNetwork = parse(result);
        } else if(statusCode != NOT_FOUND && statusCode != UNAUTHORISED){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, result));
        }
        return null;
    }

    /************************************************************************************
    Method Name  : unlinkSocialNetworkAccount
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Function     : Delete the existing social account link on the commerece server for specific account
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void unlinkSocialNetworkAccount() {

        //get endpoint
        String endpoint = getEndpointSetting(Constants.SOCIAL_REGISTRATION_DELETE_END_POINT);
        if(endpoint == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                    String.format(Label.Social_Connections_Custom_Setting_Missing, new List<String>{Constants.SOCIAL_REGISTRATION_DELETE_END_POINT})));
            return;
        }
        endpoint = String.format(endpoint, new List<String>{accountId, selectedNetwork.toLowerCase()}); 

        HttpRequest req = new HttpRequest();
        Http http = new Http();
        // Create callout request
        req.setMethod(DEL);
        req.setHeader(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
        req.setHeader(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
        req.setEndpoint(endpoint);
        //get server response
        HttpResponse response = new HttpResponse();
        if(!Test.isRunningTest()) response = http.send(req);
        else response = testResponse;

        if(response.getStatusCode() == GONE) mapSocialNetwork.remove(selectedNetwork);
        else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, response.getBody()));
    }

    public Integer getMapSize(){
        return mapSocialNetwork.size();
    }

    public class SocialProfile {
        public String email { get; set; }
    }

    /************************************************************************************
    Method Name  : parse
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Function     : JSON parsing method to return the Map of the parsed SocialProfile classes
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/    
    public static Map<String, SocialProfile> parse(String json){
        return (Map<String,SocialProfile>) System.JSON.deserialize(json, Map<String, SocialProfile>.class);
    }

    /************************************************************************************
    Method Name  : getEndpointSetting
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Function     : JSON parsing method to return the Map of the parsed SocialProfile classes
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/    
    public static String getEndpointSetting(String settingName){
        Application_Settings__c setting = Application_Settings__c.getInstance(settingName);
        if(setting != null){
            return setting.Value__c;             
        } else {
            return null;
        }
    }
}