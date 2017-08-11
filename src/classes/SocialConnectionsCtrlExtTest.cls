@isTest
private class SocialConnectionsCtrlExtTest {

	public static final Integer ACCOUNT_SIZE = 1;
	public static final String BAD_REQUEST = 'Bad Request';
	public static final String ERROR_BODY = 'Error';
	public static final String STATUS_OK = 'OK';
	public static final String FACEBOOK = 'FACEBOOK';
	public static String testUnlinkResponseBody = '{"FACEBOOK":"unlinked"}';
    public static final String testSocialProfilesBody = '{'
        + '"FACEBOOK": {'
        + '"id": "test123",'
        + '"first_name": "Facebook",'
        + '"last_name": "User",'
        + '"email": "facebook.user@test.com",'
        + '"network": "FACEBOOK"'
        +'},'
        + '"GOOGLE": {'
        + '"id": "test321",'
        + '"first_name": "Google",'
        + '"screen_name": "User",'
        + '"email": "google.user@test.com",'
        + '"network": "GOOGLE"'
        +'}'
    +'}';

    /************************************************************************************
  	Method Name  : testSetup
  	Author       : Mantas Grigaliunas
  	Created Date : 20/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@testSetup static void testSetup(){
		TestDataUtility tdu = new TestDataUtility(ACCOUNT_SIZE);
		tdu.createIndividualSubscribers();
		tdu.createSocialRegistrationEndPointSettings();
	}

	/************************************************************************************
  	Method Name  : testInitialize
  	Author       : Mantas Grigaliunas
  	Created Date : 20/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testInitialize() {

		Account testAcc = [SELECT Id FROM Account LIMIT 1];
		Test.startTest();
		SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
			new ApexPages.StandardController(testAcc));
		invokeContinuation(ctrlExt, testSocialProfilesBody, SocialConnectionsCtrlExt.OK, STATUS_OK);
		Test.stopTest();
		// Verify that the map contains the values from response
        System.assertEquals(2, ctrlExt.mapSocialNetwork.size());
        System.assertEquals(ctrlExt.mapSocialNetwork.size(), ctrlExt.getMapSize());
	}

    /************************************************************************************
    Method Name  : testInitializeNoCustomSetting
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void testInitializeNoCustomSetting() {

        delete Application_Settings__c.getInstance(Constants.SOCIAL_REGISTRATION_GET_END_POINT);

        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
            new ApexPages.StandardController(testAcc));
        invokeContinuation(ctrlExt, testSocialProfilesBody, SocialConnectionsCtrlExt.OK, STATUS_OK);
        Test.stopTest();

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.format(Label.Social_Connections_Custom_Setting_Missing , new List<String>{Constants.SOCIAL_REGISTRATION_GET_END_POINT})), 
            ApexPages.getMessages());

    }

	/************************************************************************************
  	Method Name  : testInitializeNotFound
  	Author       : Mantas Grigaliunas
  	Created Date : 20/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testInitializeNotFound() {

		Account testAcc = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();
		SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
			new ApexPages.StandardController(testAcc));
		invokeContinuation(ctrlExt, ERROR_BODY, 404, 'Not Found');
		Test.stopTest();

        System.assertEquals(0, ctrlExt.mapSocialNetwork.size());
        System.assertEquals(0, ApexPages.getMessages().size(), ApexPages.getMessages());
	}

  /************************************************************************************
  Method Name  : testInitializeUnauthorised
  Author       : Mantas Grigaliunas
  Created Date : 20/09/2016
  Change Log:
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  * Developer    Date         Description
  * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  *************************************************************************************/
  @isTest static void testInitializeUnauthorised() {

    Account testAcc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
      new ApexPages.StandardController(testAcc));
    invokeContinuation(ctrlExt, ERROR_BODY, 401, 'Unauthorised');
    Test.stopTest();

        System.assertEquals(0, ctrlExt.mapSocialNetwork.size());
        System.assertEquals(0, ApexPages.getMessages().size(), ApexPages.getMessages());
  }

  /************************************************************************************
  Method Name  : testInitializeServerError
  Author       : Mantas Grigaliunas
  Created Date : 20/09/2016
  Change Log:
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  * Developer    Date         Description
  * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  *************************************************************************************/
  @isTest static void testInitializeServerError() {

    Account testAcc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
      new ApexPages.StandardController(testAcc));
    invokeContinuation(ctrlExt, ERROR_BODY, 400, BAD_REQUEST);
    Test.stopTest();

    System.assertEquals(0, ctrlExt.mapSocialNetwork.size());
    System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), ERROR_BODY), ApexPages.getMessages());
  }
	
	/************************************************************************************
  	Method Name  : testUnlinkSocialNetworkAccount
  	Author       : Mantas Grigaliunas
  	Created Date : 20/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testUnlinkSocialNetworkAccount() {

		Account testAcc = [SELECT Id FROM Account LIMIT 1];

		HttpResponse unlinkResponse = new HttpResponse();
		unlinkResponse.setHeader('Test', 'Header');
		unlinkResponse.setStatusCode(SocialConnectionsCtrlExt.GONE);
		unlinkResponse.setBody(testUnlinkResponseBody);

		Test.startTest();
		SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
			new ApexPages.StandardController(testAcc));
		invokeContinuation(ctrlExt, testSocialProfilesBody, SocialConnectionsCtrlExt.OK, STATUS_OK);
		ctrlExt.testResponse = unlinkResponse;
		ctrlExt.selectedNetwork = FACEBOOK;
		ctrlExt.unlinkSocialNetworkAccount();
		Test.stopTest();

		System.assertEquals(1, ctrlExt.mapSocialNetwork.size());
		System.assertEquals(ctrlExt.mapSocialNetwork.size(), ctrlExt.getMapSize());
	}

    /************************************************************************************
    Method Name  : testInitializeNoCustomSetting
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void testUnlinkSocialNetworkAccountNoCustomSetting() {

        delete Application_Settings__c.getInstance(Constants.SOCIAL_REGISTRATION_DELETE_END_POINT);

        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
            new ApexPages.StandardController(testAcc));
        invokeContinuation(ctrlExt, testSocialProfilesBody, SocialConnectionsCtrlExt.OK, STATUS_OK);
        ctrlExt.unlinkSocialNetworkAccount();
        Test.stopTest();

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.format(Label.Social_Connections_Custom_Setting_Missing , new List<String>{Constants.SOCIAL_REGISTRATION_DELETE_END_POINT})), 
            ApexPages.getMessages());

    }

	/************************************************************************************
  	Method Name  : testUnlinkSocialNetworkAccountServerError
  	Author       : Mantas Grigaliunas
  	Created Date : 20/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testUnlinkSocialNetworkAccountServerError() {

		Account testAcc = [SELECT Id FROM Account LIMIT 1];

		HttpResponse errorResponse = new HttpResponse();
		errorResponse.setHeader('Test', 'Header');
		errorResponse.setStatusCode(400);
		errorResponse.setStatus(BAD_REQUEST);
		errorResponse.setBody(ERROR_BODY);

		Test.startTest();
		SocialConnectionsCtrlExt ctrlExt = new SocialConnectionsCtrlExt(
			new ApexPages.StandardController(testAcc));
		invokeContinuation(ctrlExt, testSocialProfilesBody, SocialConnectionsCtrlExt.OK, STATUS_OK);
		ctrlExt.testResponse = errorResponse;
		ctrlExt.selectedNetwork = FACEBOOK;
		ctrlExt.unlinkSocialNetworkAccount();
		Test.stopTest();

		System.assertEquals(2, ctrlExt.mapSocialNetwork.size());
		System.assertEquals(ctrlExt.mapSocialNetwork.size(), ctrlExt.getMapSize());
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), errorResponse.getBody()), ApexPages.getMessages());
	}

	/************************************************************************************
    Method Name  : invokeContinuation
    Author       : Mantas Grigaliunas
    Created Date : 20/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  *************************************************************************************/
	public static void invokeContinuation(SocialConnectionsCtrlExt ctrlExt, String body, Integer code, String codeStatus){
		// Invoke the continuation by calling the action method
        Continuation conti = (Continuation)ctrlExt.initialize();
        if(conti != null){
            // Verify that the continuation has the proper requests
            Map<String, HttpRequest> requests = conti.getRequests();
            System.assert(requests.size() == 1);
            System.assert(requests.get(ctrlExt.requestLabel) != null);

            //Generate mock response
            Map<String, String> headersMap = new Map<String, String>();
    		    headersMap.put(Constants.CORE_API_APP_ID_KEY_NAME, Constants.CORE_API_APP_ID_VALUE);
            headersMap.put(Constants.CORE_API_APP_KEY_NAME, Constants.CORE_API_APP_VALUE);
    		    HttpResponse response = new HttpResponse();
            for (String key : headersMap.keySet()) {
                response.setHeader(key, headersMap.get(key));
            }
            response.setBody(body);
            response.setStatusCode(code);
            response.setStatus(codeStatus);

            // Set the fake response for the continuation     
            Test.setContinuationResponse(ctrlExt.requestLabel, response);
            // Invoke callback method
            Object result = Test.invokeContinuationMethod(ctrlExt, conti);
            // result is the return value of the callback
            System.assertEquals(null, result);
            // Verify that the controller's result variable is set to the mock response.
            System.assertEquals(body, ctrlExt.result);
        }
  	}
}