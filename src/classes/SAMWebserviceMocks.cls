/**
* @author Wiktor Czykin
* @date 15/05/2015
* @description 	webservice mocks for SAM callouts 
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
public class SAMWebserviceMocks {
	
	public static final String SAMREQUEST_ADDENTITLEMENTS = 'AddEntitlementEndpoint';
    public static final String SAMREQUEST_AUTHENTICATE = 'AuthenticateEndpoint';
    public static final String SAMREQUEST_REMOVEENTITLEMENT = 'RemoveEntitlementEndpoint';
    public static final String SAMREQUEST_USERDETAILS= 'GetUserDetailsEndpoint';
    public static final String SAMREQUEST_CHANGEPASSWORD= 'ChangePasswordEndpoint';
	
	public static final String PARAM_ISFAILURE = 'isfailure';
	
	public static Map<String, String> MAP_ENDPOINT_RESPONSE;
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 02/09/2015
    Version - 1.0
    Function - has to be a separate method as have to have replaced base url before value can be used as a key
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void initializeEndpoints(List<SAMHTTPSettings__c> lstEndpoints){
        if(MAP_ENDPOINT_RESPONSE != null) return;
        Map<String, String> mapEndpoints = new Map<String, String>();
        for(SAMHTTPSettings__c setting : lstEndpoints){
    		if(!mapEndpoints.containsKey(setting.Name)){
    			mapEndpoints.put(setting.value__c, setting.Name);
    		}
    	}
        MAP_ENDPOINT_RESPONSE = mapEndpoints;
    }

    /************************************************************************************
    Developer - Wiktor Czykin 
    Date - 15/05/2015
    Version - 1.0
    Function - mock for SAM entitlement update
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
	public static StaticResourceCalloutMock getSAMEntitlementSuccessUpdateMock(){
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SAMEntitlementsUpdate_Success');
        mock.setStatusCode(200);
        return mock;
    }

    /************************************************************************************
    Developer - Wiktor Czykin 
    Date - 15/05/2015
    Version - 1.0
    Function - 	multi mock that returns responses based on endpoints,
    			endpoints from custom settings passed in as param,
    			static map maps endpoints to specific static resources containing response
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
    public static MultiStaticResourceCalloutMock getMultiEndpointMock(List<SAMHTTPSettings__c> lstEndpoints){

    	MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
    	for(SAMHTTPSettings__c setting : lstEndpoints){
    		if(MAP_ENDPOINT_RESPONSE.containsKey(setting.Name)){
    			multimock.setStaticResource(setting.value__c, MAP_ENDPOINT_RESPONSE.get(setting.Name));
    		}
    	}
		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'application/xml');
		return multimock;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - Authentication SAM request responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getTestAuthenticationXML(){
        String sResponse = '';
        sResponse += '<ns2:authenticationResponse xmlns="http://www.evolok.com/api/types" xmlns:ns2="http://www.evolok.com/api/sessions">';
        sResponse += '<ns2:status><code>SUCCESS</code></ns2:status>';
        sResponse += '<ns2:sessionKey>Z0lsSjNIT2hENXNpdGxoWklSeEc2V29RSWZSQ2VNODh3eVhOWmdnYU5lYVdZUDZQL1QyOC9nPT0</ns2:sessionKey>';
        sResponse += '<ns2:securitySessionKey>UFBRM3RjNEViSzBMdFlQL28yYlJDL2NiYURpSE1seVlyRy9sV29XOExQVHZtbTFtU2dTV1pRPT0</ns2:securitySessionKey>';
        sResponse += '<ns2:accountStatus>ACTIVE</ns2:accountStatus>';
        sResponse += '<ns2:publicId>2ac60ba2-384f-4503-8f0d-449e55ac5497</ns2:publicId>';
        sResponse += '<ns2:attemptsRemaining>0</ns2:attemptsRemaining>';
        sResponse += '<ns2:lockoutExpiry>0</ns2:lockoutExpiry>';
        sResponse += '<ns2:sessionExpiryTime>15</ns2:sessionExpiryTime>';
        sResponse += '</ns2:authenticationResponse>';
        
        return sResponse;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - get SAM user details request responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getSAMUserDetailsXML(){
        String sResponse = '';
        sResponse += '<ns2:userDetailsResponse xmlns="http://www.evolok.com/api/types" xmlns:ns2="http://www.evolok.com/api/users">';
        sResponse += '<ns2:status><code>SUCCESS</code></ns2:status>';
        sResponse += '<ns2:accountStatus>ACTIVE</ns2:accountStatus>';
        sResponse += '<ns2:accountVerificationStatus><verified>false</verified><verificationKey>e8f26437-9759-4fdb-95b1-1fd99c03d8b3</verificationKey></ns2:accountVerificationStatus>';
        sResponse += '<ns2:termsAndConditionsAgreed>true</ns2:termsAndConditionsAgreed>';
        sResponse += '<ns2:attributes><name>ADDRESS_LINE1</name><value>LINE1</value></ns2:attributes>';
        sResponse += '<ns2:guid>1f43ef9a-37c4-4151-92f1-c5c13cb13347</ns2:guid>';
        sResponse += '<ns2:publicId>87da14c1-0c39-47e7-834a-db8d1d84534f</ns2:publicId>';
        sResponse += '<ns2:emailAddress>testuser28102010_153247826@firstclarity.co.uk</ns2:emailAddress>';
        sResponse += '<ns2:title>Mr</ns2:title>';
        sResponse += '<ns2:firstName>fnTestUser</ns2:firstName>';
        sResponse += '<ns2:lastName>snTestUser</ns2:lastName>';
        sResponse += '</ns2:userDetailsResponse>';
        
        return sResponse;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - get SAM user details request responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getAddRemoveEntitlementsXML(){
        String sResponse = '';
        sResponse += '<basicResponse xmlns="http://www.evolok.com/api/types">';
        sResponse += '<status><code>SUCCESS</code></status>';
        sResponse += '</basicResponse>';
        
        return sResponse;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/12/2015
    Version - 1.0
    Function - get SAM lost password responses
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getSAMPasswordChangeXML(){
        String sResponse = '';
        sResponse += '<ns2:basicUserResponse#xmlns="http://www.evolok.com/api/types"#xmlns:ns2="ht tp://www.evolok.com/api/users">';
        sResponse += '<ns2:status><code>SUCCESS</code></ns2:status>';
        sResponse += '</ns2:basicUserResponse>';
        
        return sResponse;
    }
    
    public class SAMHttpResponseGenerator implements HttpCalloutMock{
        public Map<String, String> mapParams{get;set;}
        private String sBaseUrl{get;set;}

        /*************************************************************************************** 
        Developer - Cristina Anghenie
        Date - 02/09/2015v
        Version - 1.0
        Function - constructor - needs baseUrl to generate map with mappings and optional map of parameters
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public SAMHttpResponseGenerator(List<SAMHTTPSettings__c> lstSAMHTTPSettings){
            this.mapParams = mapParams;
            this.sBaseUrl = sBaseUrl;
            SAMWebserviceMocks.initializeEndpoints(lstSAMHTTPSettings);
        }

        /*************************************************************************************** 
        Developer - Cristina Anghenie
        Date - 02/09/2015
        Version - 1.0
        Function - implemented method that returns response visible in the test flow
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody(getRequestEndpointData(req));
            res.setStatusCode(200);
            return res;
        }
        
        /*************************************************************************************** 
        Developer - Cristina Anghenie
        Date - 02/09/2015
        Version - 1.0
        Function - method that returns proper xml depending on the enpoint
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        private String getRequestEndpointData(HTTPRequest req){
            String sEndpoint = req.getEndpoint();
            sEndpoint = sEndpoint.substringBefore('?');
            if(!SAMWebserviceMocks.MAP_ENDPOINT_RESPONSE.containsKey(sEndpoint)) throw new TelegraphApplicationException('SAM endpoint not handled in test response generation:'+sEndpoint);

            String sResponseType = SAMWebserviceMocks.MAP_ENDPOINT_RESPONSE.get(sEndpoint);
            String sResponse;
            if(sResponseType == SAMREQUEST_AUTHENTICATE){
                sResponse = SAMWebserviceMocks.getTestAuthenticationXML();
            }else if(sResponseType == SAMREQUEST_USERDETAILS){
                sResponse = SAMWebserviceMocks.getSAMUserDetailsXML();
            }else if(sResponseType == SAMREQUEST_ADDENTITLEMENTS || sResponseType == SAMREQUEST_REMOVEENTITLEMENT){
            	sResponse = SAMWebserviceMocks.getAddRemoveEntitlementsXML();
            }else if(sResponseType == SAMREQUEST_CHANGEPASSWORD){
            	sResponse = SAMWebserviceMocks.getSAMPasswordChangeXML();
            }
            
            return sResponse;
        }
    }
}