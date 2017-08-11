/************************************************************************************
Class Name   : IdentityUtilityTest
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Test Class for IdentityUtility class
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@IsTest
public class IdentityUtilityTest {

    @TestSetup private static void setupData(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.CreateCoreApiEndPointSettings();
        tdu.createMyNewslettersEndPointSettings();
    }

    public static Map<String, Object> IDENTITY_MAP = new Map<String, Object>{
        'grant_type' => 'password',
        'credential_type' => 'TS_NUMBER',
        'identifier' => 'tsNumber',
        'auth_key' => 'postCode',
        'client_id' => 'tcuk',
        'remember_me' => true
    };

    public static Map<String, String> HEADER_MAP = new  Map<String, String>{
        Constants.CORE_API_APP_ID_KEY_NAME => Constants.CORE_API_APP_ID_VALUE,
        Constants.CORE_API_APP_KEY_NAME => Constants.CORE_API_APP_VALUE,
        Constants.CORE_API_CONTENT_TYPE_KEY_VALUE => Constants.CORE_API_JSON_CONTENT_TYPE_VALUE
    };

    public static Map<String, Object> IDENTITY_RESPONSE_MAP = new Map<String, Object>{
        'access_token' => 'access_token',
        'refresh_token' => 'refresh_token',
        'id_token' => 'id_token',
        'livefyre_token' => 'livefyre_token',        
        'token_type' => 'token_type',
        'expires_in' => 1
    };

    public static String IDENTITY_RESPONSE_JSON { 
        get { 
            return JSONUtility.getJSONString(IDENTITY_RESPONSE_MAP); 
        }
    }

    /************************************************************************************
    Method Name  : testJSONUtility
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Test method to assert response from IdentityUtility, Assert against IDENTITY_RESPONSE_MAP
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static TestMethod void testIdentityUtility(){
        Test.startTest();

        IdentityWrapper idWrapper = getIdentity();

        System.assertEquals(IDENTITY_RESPONSE_MAP.get('access_token'), idWrapper.access_token);
        System.assertEquals(IDENTITY_RESPONSE_MAP.get('refresh_token'), idWrapper.refresh_token);
        System.assertEquals(IDENTITY_RESPONSE_MAP.get('id_token'), idWrapper.id_token);
        System.assertEquals(IDENTITY_RESPONSE_MAP.get('livefyre_token'), idWrapper.livefyre_token);
        System.assertEquals(IDENTITY_RESPONSE_MAP.get('token_type'), idWrapper.token_type);
        System.assertEquals(IDENTITY_RESPONSE_MAP.get('expires_in'), idWrapper.expires_in);

        Test.stopTest();
	}

    /************************************************************************************
    Method Name  : getIdentity
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Get Identity wrapper from IdentityUtility. response generated using MockResponseGenerator.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static IdentityWrapper getIdentity(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(201, 'created', IDENTITY_RESPONSE_JSON, new Map<String, String>()));
        CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
        return calloutUtility.getIdentity(IDENTITY_MAP, HEADER_MAP);
    }
}