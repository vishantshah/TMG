/*
 * File Name   : SAMInterfaceHTTP
 * Description : Class that handles HTTP communications to SAM
 *
 * Modification Log
 * ========================================================
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version
 * 1.1 28/11/2016 Michal Szewczyk  Added methods to call getExistingAccount (checkExistingEmail, joinService,fetchAllEntitlements, findUser)
 * 1.2 12/12/2016 Michal Szewczyk  Added methods to call createAccount (registerDigitalUser, lostPasswordRequest, resolveIdBySession, logoff )
 */
public with sharing class SAMInterfaceHTTP {
	//Properties
	public static String addEntitlementUrl {get;set;}
	public static String authUrl {get;set;}
	public static String brokerUrl {get;set;}
	public static String changeEmailUrl {get;set;}
	public static String logoffUrl {get;set;}
	public static String lostPasswordRequestUrl {get;set;}
	public static String registerDigitalUserUrl {get;set;}
	public static String removeEntitlementUrl {get;set;}
	public static String resolveIdBySessionUrl {get;set;}
	public static String findUserUrl {get;set;}
	public static String fetchAllEntitlementsUrl {get;set;}
	public static String joinServiceUrl {get;set;}
	public static String checkEmailAddressUrl {get;set;}
	public static String serviceKey {get;set;}
	public static String userDetailsUrl {get;set;}
	public static String alterSalesforceEntitlementUrl {get;set;}
	public static String updateUserUrl {get;set;}
	public enum  AuthenticationType {GUID, PASSWORD}
	public enum  EntitlementUpdateType {ADD, REMOVE}

	/***************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/05/2016
    Version - 1.0
    Function - POST method to check email address in SAM
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static SubscriptionsSAMWebservices.salesforceResponse checkExistingAccount (String email){
		if(!checkSettings()){
			throw new CheckExistingEmailException(Label.SAMHTTPSettings_Incomplete);
		}
		SubscriptionsSAMWebservices.salesforceResponse result = new SubscriptionsSAMWebservices.salesforceResponse() ;
		checkEmailAddressResponse emailResponse = checkExistingEmail(email);
		result.guid = emailResponse.guid;
		result.status = emailResponse.status;
		return result;
	}

	/***************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/05/2016
    Version - 1.0
    Function - POST method fetching account information from SAM
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static SubscriptionsSAMWebservices.salesforceResponse getExistingAccount (String email){
		if(!checkSettings()){
			throw new CheckExistingEmailException(Label.SAMHTTPSettings_Incomplete);
		}
		SubscriptionsSAMWebservices.salesforceResponse result = new SubscriptionsSAMWebservices.salesforceResponse() ;
		checkEmailAddressResponse emailResponse = checkExistingEmail(email);
		result.guid = emailResponse.guid;
		result.status = emailResponse.status;
		if(result.status == Constants.SAM_ACCOUNT_NOT_FOUND) {
			return result;
		}
		authenticateUserResponse ar = callAuthenticateUser(email, result.guid, SAMInterfaceHTTP.AuthenticationType.GUID);
		joinService (result.guid,ar.sessionKey);
		result.entitlements = fetchAllEntitlements(result.guid,ar.sessionKey);
		result.status = findUser(result.guid);
		return result;
	}
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/05/2016
    Version - 1.0
    Function - POST method feching all Entitlements from SAM
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static List<String> fetchAllEntitlements (String guid,String sessionKey){
		String statusCode;
		Boolean foundStatus;
		Boolean callResults = false;
		List<String> allEnt = new List<String>();
		String xmlBodyTemplate;

		xmlBodyTemplate = getSAMRequestBodyTemplate('SAMFetchAllEntitlements');
		List<String> envelopeParameterList = new List<String>{serviceKey,sessionKey};
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(fetchAllEntitlementsUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);

		for(DOM.Xmlnode node : responseDoc.getRootElement().getChildElements()){

			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}

			if(node.getName() == 'granted') {
				allEnt.add(node.getText());
			}
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return allEnt;
		}else{
			throw new FetchAllEntitlementsException(Label.UnknownSAMFetchAllEntitlementsError);
		}
	}



    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/05/2016
    Version - 1.0
    Function - POST method checking that account exist in SAM
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static String findUser (String guid){
		String statusCode;
		Boolean foundStatus;
		String retValue='';
		Boolean callResults = false;
		String xmlBodyTemplate;

		xmlBodyTemplate = getSAMRequestBodyTemplate('SAMFindUser');
		List<String> envelopeParameterList = new List<String>{serviceKey,guid,'false'};

		Dom.Document responseDoc = TMGAPIUtils.callOutPost(findUserUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);

		for(DOM.Xmlnode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}
			if(node.getName() == 'accountStatus') {
				retValue = node.getText();
			}
		}
		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return retValue;
		}else{
			throw new FindUserException(Label.UnknownSAMFindUserError);
		}
	}

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/05/2016
    Version - 1.0
    Function - POST method that need to be revoke in this order
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static String joinService (String guid,String sessionKey){
		String statusCode;
		Boolean foundStatus;
		Boolean callResults = false;
		//String guid = '';
		String xmlBodyTemplate;

		xmlBodyTemplate = getSAMRequestBodyTemplate('SAMJoinService');
		List<String> envelopeParameterList = new List<String>{serviceKey,sessionKey,guid};

		Dom.Document responseDoc = TMGAPIUtils.callOutPost(joinServiceUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);

		for(DOM.Xmlnode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return guid;
		}else{
			throw new JoinServiceException(Label.UnknownSAMJoinServiceError);
		}

	}
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/05/2016
    Version - 1.0
    Function - POST method checking that account exist in SAM
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static checkEmailAddressResponse checkExistingEmail (String email){
		String statusCode;
		Boolean foundStatus;
		Boolean callResults = false;
		String guid = '';
		String xmlBodyTemplate;
		checkEmailAddressResponse response = new checkEmailAddressResponse();
		xmlBodyTemplate = getSAMRequestBodyTemplate('SAMCheckEmail');
		List<String> envelopeParameterList = new List<String>{serviceKey,email};
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(checkEmailAddressUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);

		for(DOM.Xmlnode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						response.status = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}
			if(node.getName() == 'guid') {
				response.guid = node.getText();
			}
			if(node.getName() == 'emailAddressExists') {}
		}
		//Validate result
		if(response.status == Constants.SAM_SUCCESS_CODE || response.status == Constants.SAM_ACCOUNT_NOT_FOUND){
			return response;
		}else{
			throw new CheckExistingEmailException(Label.UnknownCheckExistingEmail);
		}
	}

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 14/12/2016
    Function - POST method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static SubscriptionsSAMWebservices.salesforceResponse updateAccount(SubscriptionsSAMWebservices.commonRequest userDetails,String guid){
		/*
		POST http://auth.telegraph.co.uk/sam/service/authenticateUser
		POST http://auth.telegraph.co.uk/sam/service/updateUserDetails
		POST http://auth.telegraph.co.uk/sam/service/alterSalesforceEntitlement
		POST http://auth.telegraph.co.uk/sam/service/logoff
		*/
		if(!checkSettings()){
			throw new UpdateAccountException(Label.SAMHTTPSettings_Incomplete);
		}
		SubscriptionsSAMWebservices.salesforceResponse response = new SubscriptionsSAMWebservices.salesforceResponse();

		authenticateUserResponse ar = callAuthenticateUser(userDetails.email,guid, SAMInterfaceHTTP.AuthenticationType.GUID);
		UpdateUserResponse updateUser = updateUser(userDetails,ar.sessionKey);
		AlterSalesforceEntitlementResponse alterSalesforceEntitlement = alterSalesforceEntitlement(ar.sessionKey, userDetails.entitlements);
		LogoffResponse logoff = logoff(ar.sessionKey);
		response.status = String.valueOf(logoff.statusCode);
		return response;
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - POST method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static SubscriptionsSAMWebservices.salesforceResponse createAccount(SubscriptionsSAMWebservices.commonRequest userDetails){
		if(!checkSettings()){
			throw new CreateAccountException(Label.SAMHTTPSettings_Incomplete);
		}

		RegisterDigitalUserResponse registerDigitalUser = registerDigitalUser(userDetails);
		LostPasswordRequestResponse lostPasswordRequest = lostPasswordRequest(registerDigitalUser.sessionKey, userDetails.email);
		ResolveIdBySessionResponse resolveIdBySession = resolveIdBySession(lostPasswordRequest.sessionKey);
		LogoffResponse logoff = logoff(resolveIdBySession.sessionKey);
		SubscriptionsSAMWebservices.salesforceResponse response = new SubscriptionsSAMWebservices.salesforceResponse();
		response.guid = resolveIdBySession.guid;
		response.pid = resolveIdBySession.pid;
		response.status = String.valueOf(logoff.statusCode);
		return response;
	}

	/***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - SAM callout - registerDigitalUser
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static UpdateUserResponse updateUser(SubscriptionsSAMWebservices.commonRequest userDetails,String sessionKey){
		try{
			serviceKey = SAMHTTPSettings__c.getInstance('ServiceKey').value__c;
			updateUserUrl = SAMHTTPSettings__c.getInstance('UpdateUserEndpoint').value__c;
		}catch(Exception e){
			throw new UpdateUserException(Label.SAMHTTPSettings_Incomplete);
		}

		Boolean foundAccountStatus = false;
		String statusCode;
		String accountStatus;
		Boolean foundStatus;

		String xmlBodyTemplate = getSAMRequestBodyTemplate('SAMUpdateUser');
		List<String> envelopeParameterList = new List<String>{serviceKey, userDetails.title, userDetails.firstname, userDetails.lastname, userDetails.email,'Fdks213DFsss',
															String.valueOf(userDetails.marketingPhonePref), String.valueOf(userDetails.marketingEmailPref),
															String.valueOf(userDetails.marketingPostPref), String.valueOf(userDetails.marketingSMSPref),userDetails.postcode,
															String.valueOf(userDetails.subscribersOfferPref),userDetails.tsNumber,'false',userDetails.street,userDetails.county,userDetails.city,
															String.valueOf(userDetails.marketing3rdPref),userDetails.country,userDetails.postcode,'true'};

		System.debug('### SAMInterfaceHTTP.registerDigitalUser -> HTTP Request: ' + String.format(xmlBodyTemplate, envelopeParameterList));
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(updateUserUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
		System.debug('### SAMInterfaceHTTP.registerDigitalUser -> HTTP Response: ' + responseDoc.toXMLString());

		//Parse xml
		for(Dom.XMLNode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}

			if(foundStatus){
				break;
			}
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return new UpdateUserResponse(ResponseStatusCodes.SUCCESS, null, sessionKey);
		}else{
			if(statusCode == Constants.SAM_CREDENTIALS_ERROR_CODE) throw new UpdateUserException(Label.FailedAuthenticationError);
			else throw new UpdateUserException(Label.UnknownSAMRegisterDigitalUserError);
		}
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - SAM callout - registerDigitalUser
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static RegisterDigitalUserResponse registerDigitalUser(SubscriptionsSAMWebservices.commonRequest userDetails){
		try{
			serviceKey = SAMHTTPSettings__c.getInstance('ServiceKey').value__c;
			registerDigitalUserUrl = SAMHTTPSettings__c.getInstance('RegisterDigitalUserEndpoint').value__c;
		}catch(Exception e){
			throw new RegisterDigitalUserException(Label.SAMHTTPSettings_Incomplete);
		}

		Boolean foundStatus = false;
		Boolean foundSessionKey = false;
		Boolean foundAccountStatus = false;
		String statusCode;
		String sessionKey;
		String accountStatus;

		String xmlBodyTemplate = getSAMRequestBodyTemplate('SAMRegisterDigitalUser');
		List<String> envelopeParameterList = new List<String>{serviceKey, userDetails.title, userDetails.firstname, userDetails.lastname, userDetails.email,'Fdks213DFsss',
															String.valueOf(userDetails.marketingPhonePref), String.valueOf(userDetails.marketingEmailPref),
															String.valueOf(userDetails.marketingPostPref), String.valueOf(userDetails.marketingSMSPref),userDetails.postcode,
															String.valueOf(userDetails.subscribersOfferPref),userDetails.tsNumber,'false',userDetails.street,userDetails.county,userDetails.city,
															String.valueOf(userDetails.marketing3rdPref),userDetails.country,userDetails.postcode,'true'};

		System.debug('### SAMInterfaceHTTP.registerDigitalUser -> HTTP Request: ' + String.format(xmlBodyTemplate, envelopeParameterList));
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(registerDigitalUserUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
		System.debug('### SAMInterfaceHTTP.registerDigitalUser -> HTTP Response: ' + responseDoc.toXMLString());

		//Parse xml
		for(Dom.XMLNode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}else if(node.getName() == 'sessionKey'){
				sessionKey = node.getText();
				foundSessionKey = true;
			}else if(node.getName() == 'accountStatus'){
				accountStatus = node.getText();
				foundAccountStatus = true;
			}

			if(foundStatus && foundSessionKey && foundAccountStatus){
				break;
			}
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return new RegisterDigitalUserResponse(ResponseStatusCodes.SUCCESS, accountStatus, null, sessionKey);
		}else{
			if(statusCode == Constants.SAM_CREDENTIALS_ERROR_CODE) throw new RegisterDigitalUserException(Label.FailedAuthenticationError);
			else throw new RegisterDigitalUserException(Label.UnknownSAMRegisterDigitalUserError);
		}
	}


    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - SAM callout - lostPasswordRequest
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static LostPasswordRequestResponse lostPasswordRequest(String sessionKey, String email){
		try{
			serviceKey = SAMHTTPSettings__c.getInstance('ServiceKey').value__c;
			lostPasswordRequestUrl = SAMHTTPSettings__c.getInstance('LostPasswordRequestEndpoint').value__c;
		}catch(Exception e){
			throw new LostPasswordRequestException(Label.SAMHTTPSettings_Incomplete);
		}

		Boolean foundStatus = false;
		String statusCode;

		String xmlBodyTemplate = getSAMRequestBodyTemplate('SAMLostPasswordRequest');
		List<String> envelopeParameterList = new List<String>{serviceKey, email};

		System.debug('### SAMInterfaceHTTP.lostPasswordRequest -> HTTP Request: ' + String.format(xmlBodyTemplate, envelopeParameterList));
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(lostPasswordRequestUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
		System.debug('### SAMInterfaceHTTP.lostPasswordRequest -> HTTP Response: ' + responseDoc.toXMLString());

		//Parse xml
		for(Dom.XMLNode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}

			if(foundStatus) break;
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return new LostPasswordRequestResponse(ResponseStatusCodes.SUCCESS, null, sessionKey);
		}else{
			if(statusCode == Constants.SAM_CREDENTIALS_ERROR_CODE) throw new LostPasswordRequestException(Label.FailedAuthenticationError);
			else throw new LostPasswordRequestException(Label.UnknownSAMLostPasswordRequestError);
		}
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - SAM callout - resolveIdBySession
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static ResolveIdBySessionResponse resolveIdBySession(String sessionKey){
		try{
			serviceKey = SAMHTTPSettings__c.getInstance('ServiceKey').value__c;
			resolveIdBySessionUrl = SAMHTTPSettings__c.getInstance('ResolveIdBySessionEndpoint').value__c;
		}catch(Exception e){
			throw new ResolveIdBySessionException(Label.SAMHTTPSettings_Incomplete);
		}

		Boolean foundStatus = false;
		Boolean foundGuid = false;
		Boolean foundPid = false;
		String statusCode;
		String guid;
		String pid;

		String xmlBodyTemplate = getSAMRequestBodyTemplate('SAMResolveIdBySession');
		List<String> envelopeParameterList = new List<String>{serviceKey, sessionKey};

		System.debug('### SAMInterfaceHTTP.resolveIdBySession -> HTTP Request: ' + String.format(xmlBodyTemplate, envelopeParameterList));
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(resolveIdBySessionUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
		System.debug('### SAMInterfaceHTTP.resolveIdBySession -> HTTP Response: ' + responseDoc.toXMLString());

		//Parse xml
		for(Dom.XMLNode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}else if(node.getName() == 'guid'){
				guid = node.getText();
				foundGuid = true;
			}else if(node.getName() == 'pid'){
				pid = node.getText();
				foundPid = true;
			}

			if(foundStatus && foundGuid && foundPid){
				break;
			}
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return new ResolveIdBySessionResponse(ResponseStatusCodes.SUCCESS, guid, pid, null, sessionKey);
		}else{
			if(statusCode == Constants.SAM_CREDENTIALS_ERROR_CODE) throw new ResolveIdBySessionException(Label.FailedAuthenticationError);
			else throw new ResolveIdBySessionException(Label.UnknownSAMResolveIdBySessionError);
		}
	}

 	/***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - SAM callout - alterSalesforceEntitlement
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static AlterSalesforceEntitlementResponse alterSalesforceEntitlement(String sessionKey, String entitlements){
		try{
			serviceKey = SAMHTTPSettings__c.getInstance('ServiceKey').value__c;
			alterSalesforceEntitlementUrl = SAMHTTPSettings__c.getInstance('AlterSalesforceEntitlementEndpoint').value__c;
		}catch(Exception e){
			throw new AlterSalesforceEntitlementException(Label.SAMHTTPSettings_Incomplete);
		}

		Boolean foundStatus = false;
		String statusCode;

		String xmlBodyTemplate = getSAMRequestBodyTemplate('SAMAlterSalesforceEntitlement');
		List<String> envelopeParameterList = new List<String>{serviceKey, sessionKey, entitlements};

		System.debug('### SAMInterfaceHTTP.alterSalesforceEntitlement -> HTTP Request: ' + String.format(xmlBodyTemplate, envelopeParameterList));
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(alterSalesforceEntitlementUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
		System.debug('### SAMInterfaceHTTP.alterSalesforceEntitlement -> HTTP Response: ' + responseDoc.toXMLString());

		//Parse xml
		for(Dom.XMLNode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}

			if(foundStatus) break;
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return new AlterSalesforceEntitlementResponse(ResponseStatusCodes.SUCCESS, null, sessionKey);
		}else{
			if(statusCode == Constants.SAM_CREDENTIALS_ERROR_CODE) throw new AlterSalesforceEntitlementException(Label.FailedAuthenticationError);
			else throw new AlterSalesforceEntitlementException(Label.UnknownSAMAlterSFEntitlementError);
		}
	}
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - SAM callout - logoff
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static LogoffResponse logoff(String sessionKey){
		try{
			serviceKey = SAMHTTPSettings__c.getInstance('ServiceKey').value__c;
			logoffUrl = SAMHTTPSettings__c.getInstance('LogoffEndpoint').value__c;
		}catch(Exception e){
			throw new LogoffException(Label.SAMHTTPSettings_Incomplete);
		}

		Boolean foundStatus = false;
		String statusCode;

		String xmlBodyTemplate = getSAMRequestBodyTemplate('SAMLogoff');
		List<String> envelopeParameterList = new List<String>{serviceKey, sessionKey};

		System.debug('### SAMInterfaceHTTP.logoff -> HTTP Request: ' + String.format(xmlBodyTemplate, envelopeParameterList));
		Dom.Document responseDoc = TMGAPIUtils.callOutPost(logoffUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
		System.debug('### SAMInterfaceHTTP.logoff -> HTTP Response: ' + responseDoc.toXMLString());

		//Parse xml
		for(Dom.XMLNode node : responseDoc.getRootElement().getChildElements()){
			if(node.getName() == 'status'){
				for(Dom.XMLNode statusNode : node.getChildElements()){
					if(statusNode.getName() == 'code'){
						statusCode = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}

			if(foundStatus) break;
		}

		//Validate result
		if(statusCode == Constants.SAM_SUCCESS_CODE){
			return new LogoffResponse(ResponseStatusCodes.SUCCESS, null, sessionKey);
		}else{
			if(statusCode == Constants.SAM_CREDENTIALS_ERROR_CODE) throw new LogoffException(Label.FailedAuthenticationError);
			else throw new LogoffException(Label.UnknownSAMLogoffError);
		}
	}


	//AuthenticateUser method callout
	public static authenticateUserResponse callAuthenticateUser(string email, string identifier, AuthenticationType accessIdentifier) {
		//Get custom settings, validate all are populated
		Boolean continueProcess = checkSettings();

		//Complete xml request with parameters, do the callout, parse and validate the response
		if (continueProcess) {
			try {
				String xmlBodyTemplate;

				if(accessIdentifier == AuthenticationType.PASSWORD){
					xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAMAUTHREQUESTBODY_STATICRESOURCE_NAME);
				}
				else if(accessIdentifier == AuthenticationType.GUID){
					xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAMAUTHREQUESTBODY2_STATICRESOURCE_NAME);
				}
				authenticateUserResponse response = getAuthenticateUserResponse(TMGAPIUtils.callOutPost(authUrl, new List<String>{serviceKey, email, identifier}, xmlBodyTemplate, TMGAPIUtils.BodyType.XML));

				return response;
			}
			catch (AuthenticationException AUex) {
				return new authenticateUserResponse(ResponseStatusCodes.FAIL, AUex.getMessage());
			}
			catch (Exception ex) {
				return new authenticateUserResponse(ResponseStatusCodes.FAIL, Label.UnknownCommunicationError);
			}
		}
		else{
			return new authenticateUserResponse(ResponseStatusCodes.INCOMPLETESETTINGS, Label.UnknownError);
		}

	}

	//This was the original method, now overloaded by the method above
	public static authenticateUserResponse callAuthenticateUser(String email, String password) {
		return callAuthenticateUser(email, password, SAMInterfaceHTTP.AuthenticationType.PASSWORD);
	}

	public static SamUserDetails getUserDetails(String email, String guid){
		//If this call errors,  it should be picked up by the calling method
		authenticateUserResponse ar = callAuthenticateUser(email, guid, SAMInterfaceHTTP.AuthenticationType.GUID);

		if(ar.sessionKey != null){
			try{
				String xmlBodyTemplate,errorMessage,errorNumber;
				string url;
				xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAM_GET_USER_DETAILS_STATICRESOURCE_NAME);
				url = userDetailsUrl;
				List<String> envelopeParameterList = new List<String>{
																		serviceKey,
																		ar.sessionKey,
																		'true'
																	 };

				Dom.Document responseDoc = TMGAPIUtils.callOutPost(url, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
				System.debug(responseDoc.toXMLString());
				SamUserDetails samDetails = new SamUserDetails();
				for(DOM.Xmlnode node : responseDoc.getRootElement().getChildElements()){
					if(node.getName() == 'ErrorMessage'){
						errorMessage = node.getText();
					}
					if(node.getName() == 'ErrorNumber'){
						errorNumber = node.getText();
					}
					if(node.getName() == 'title'){
						samDetails.salutation = node.getText();
					}
					if(node.getName() == 'firstName'){
						samDetails.firstName = node.getText();
					}
					if(node.getName() == 'lastName'){
						samDetails.lastName = node.getText();
					}
					if(node.getName() == 'emailAddress'){
						samDetails.emailAddress = node.getText();
					}
					if(node.getName() == 'guid'){
						samDetails.guid = node.getText();
					}

					if(!String.isBlank(errorNumber) && !String.isBlank(errorMessage)) {
						break;
					}
				}
				return samDetails;
			}
			catch (Exception ex) {
				return null;
			}

		}
		else{
			return null;
		}
	}

	//
	public static bulkUpdateResponse updateSubscriptionEntitlement (string email, string guid, set<string> entitlements, EntitlementUpdateType updateType) {
		//If this call errors,  it should be picked up by the calling method
		authenticateUserResponse ar = callAuthenticateUser(email, guid, SAMInterfaceHTTP.AuthenticationType.GUID);

		if(ar.sessionKey != null){

			try{
				String xmlBodyTemplate;
				string url;

				if(updateType == EntitlementUpdateType.ADD){
					xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAMUPDATE_ADD_ENTITLEMENT_REQUESTBODY_STATICRESOURCE_NAME);
					url = addEntitlementUrl;
				}
				else if(updateType == EntitlementUpdateType.REMOVE){
					xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAMUPDATE_REMOVE_ENTITLEMENT_REQUESTBODY_STATICRESOURCE_NAME);
					url = removeEntitlementUrl;
				}

				string entitlementChanges = '';
				for(string entitlement : entitlements){
					entitlementChanges += '<user:entitlements>' + entitlement + '</user:entitlements>';
				}

				List<String> envelopeParameterList = new List<String>{
																		serviceKey,
																		ar.sessionKey,
																		entitlementChanges
																	 };

				Dom.Document responseDoc = TMGAPIUtils.callOutPost(url, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
				System.debug(responseDoc.toXMLString());
				return new bulkUpdateResponse(ResponseStatusCodes.SUCCESS);
			}
			catch (Exception ex) {
				return new bulkUpdateResponse(ResponseStatusCodes.FAIL, Label.UnknownCommunicationError);
			}

		}
		else{
			return new bulkUpdateResponse(ResponseStatusCodes.FAIL, ar.message);
		}

	}

	public static String resetPassword(String email, String guid){
        //If this call errors,  it should be picked up by the calling method
        authenticateUserResponse ar = callAuthenticateUser(email, guid, SAMInterfaceHTTP.AuthenticationType.GUID);

        if(ar.sessionKey != null){
            try{
                String xmlBodyTemplate,errorMessage,errorNumber;
                string url;
                xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAM_PASSWORD_RESET);
                url = changeEmailUrl;
                List<String> envelopeParameterList = new List<String>{
                                                                        serviceKey,
                                                                        email
                                                                     };
                Dom.Document responseDoc = TMGAPIUtils.callOutPost(url, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
                System.debug(responseDoc.toXMLString());
                return Constants.SAM_SUCCESS_CODE;
            }
            catch (Exception ex) {
                return Constants.SAM_PASSWORD_FAILURE;
            }

        }
        else{
            return Constants.SAM_PASSWORD_FAILURE;
        }

    }

	//Bulkupdate method callout
	public static bulkUpdateResponse callBulkUpdate(Set<String> samGUIDs, String entitlement) {
		//Get custom settings, validate all are populated
		Boolean continueProcess = checkSettings();

		//Complete xml request with parameters, do the callout, parse and validate the response
		if (continueProcess) {
			try {
				String xmlBodyTemplate = getSAMRequestBodyTemplate(Constants.SAMBULKUPDATE_ENV_REQUESTBODY_STATICRESOURCE_NAME);
				String xmlNotificationTemplate = getSAMRequestBodyTemplate(Constants.SAMBULKUPDATE_NOT_REQUESTBODY_STATICRESOURCE_NAME);
				String notificationTemp = '';
				List<String> notificationParameterList;
				for (String guid : samGUIDs) {
					notificationParameterList = new List<String>{
																	guid,
																	'',
																	entitlement,
																	serviceKey,
																	Datetime.now().format('yyyy-MM-dd') + 'T' + Datetime.now().format('HH:mm:ss')
																};
					notificationTemp += String.format(xmlNotificationTemplate, notificationParameterList);
				}

				List<String> envelopeParameterList = new List<String>{
																		 notificationTemp,
																		 String.valueOf(datetime.now().getTime()),
																		 serviceKey
																	 };
				Dom.Document responseDoc = TMGAPIUtils.callOutPost(brokerUrl, envelopeParameterList, xmlBodyTemplate, TMGAPIUtils.BodyType.XML);
				System.debug(responseDoc.toXMLString());
				return new bulkUpdateResponse(ResponseStatusCodes.SUCCESS);
			}
			catch (Exception ex) {
				return new bulkUpdateResponse(ResponseStatusCodes.FAIL, Label.UnknownCommunicationError);
			}
		}
		else {
			return new bulkUpdateResponse(ResponseStatusCodes.INCOMPLETESETTINGS, Label.UnknownError);
		}
	}

	//Method that checks the custom settings and tells the process to continuo or stop
	public static Boolean checkSettings() {
		Boolean continueProcess = true;

		Map<String, SAMHTTPSettings__c> SAMHTTPSettings = SAMHTTPSettings__c.getAll();
		if (SAMHTTPSettings.containsKey('AuthenticateEndpoint')) {
			authUrl = SAMHTTPSettings.get('AuthenticateEndpoint').value__c;
		}
		else {
			continueProcess = false;
		}
		if (SAMHTTPSettings.containsKey('ServiceKey') && continueProcess) {
			serviceKey = SAMHTTPSettings.get('ServiceKey').value__c;
		}
		else {
			continueProcess = false;
		}
		if (SAMHTTPSettings.containsKey('BrokerEndpoint') && continueProcess) {
			brokerUrl = SAMHTTPSettings.get('BrokerEndpoint').value__c;
		}
		else {
			continueProcess = false;
		}
		if (SAMHTTPSettings.containsKey('AddEntitlementEndpoint') && continueProcess) {
			addEntitlementUrl = SAMHTTPSettings.get('AddEntitlementEndpoint').value__c;
		}
		else {
			continueProcess = false;
		}
		if (SAMHTTPSettings.containsKey('RemoveEntitlementEndpoint') && continueProcess) {
			removeEntitlementUrl = SAMHTTPSettings.get('RemoveEntitlementEndpoint').value__c;
		}
		else {
			continueProcess = false;
		}

		if(SAMHTTPSettings.containsKey('AlterSalesforceEntitlementEndpoint')){
			alterSalesforceEntitlementUrl = SAMHTTPSettings.get('AlterSalesforceEntitlementEndpoint').value__c;
		}else{
			return false;
		}

		if (SAMHTTPSettings.containsKey('GetUserDetailsEndpoint') && continueProcess) {
			userDetailsUrl = SAMHTTPSettings.get('GetUserDetailsEndpoint').value__c;
		}
		else {
			continueProcess = false;
		}

		if (SAMHTTPSettings.containsKey('ChangePasswordEndpoint') && continueProcess) {
            changeEmailUrl = SAMHTTPSettings.get('ChangePasswordEndpoint').value__c;
        }
        else {
            continueProcess = false;
        }

		if(SAMHTTPSettings.containsKey('FindUserEndpoint')){
			findUserUrl = SAMHTTPSettings.get('FindUserEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('FetchAllEntitlementEndpoint')){
			fetchAllEntitlementsUrl = SAMHTTPSettings.get('FetchAllEntitlementEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('JoinServiceEndpoint')){
			joinServiceUrl = SAMHTTPSettings.get('JoinServiceEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('CheckExistingEmailEndpoint')){
			checkEmailAddressUrl = SAMHTTPSettings.get('CheckExistingEmailEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('RegisterDigitalUserEndpoint')){
			registerDigitalUserUrl = SAMHTTPSettings.get('RegisterDigitalUserEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('LogoffEndpoint')){
			logoffUrl = SAMHTTPSettings.get('LogoffEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('LostPasswordRequestEndpoint')){
			lostPasswordRequestUrl = SAMHTTPSettings.get('LostPasswordRequestEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('ResolveIdBySessionEndpoint')){
			resolveIdBySessionUrl = SAMHTTPSettings.get('ResolveIdBySessionEndpoint').value__c;
		}else{
			return false;
		}

		if(SAMHTTPSettings.containsKey('UpdateUserEndpoint')){
			resolveIdBySessionUrl = SAMHTTPSettings.get('UpdateUserEndpoint').value__c;
		}else{
			return false;
		}

		return continueProcess;
	}

	//Parse and validate AuthenticateUser method's Response
	public static authenticateUserResponse getAuthenticateUserResponse(Dom.Document response) {
		String resultString;
		String sessionKey;
		boolean foundStatus = false;
		boolean foundSessionKey = false;

		//Parse xml
		for (Dom.XMLNode node : response.getRootElement().getChildElements()) {
			if (node.getName() == 'status') {
				for (Dom.XMLNode statusNode : node.getChildElements()) {
					if (statusNode.getName() == 'code') {
						resultString = statusNode.getText();
						foundStatus = true;
						break;
					}
				}
			}
			else if(node.getName() == 'sessionKey') {
				sessionKey = node.getText();
				foundSessionKey = true;
			}

			if(foundStatus && foundSessionKey){
				break;
			}

		}

		//Validate obtained result
		if (resultString != Constants.SAM_SUCCESS_CODE) {
			if (resultString == Constants.SAM_CREDENTIALS_ERROR_CODE)
				throw new AuthenticationException(Label.FailedAuthenticationError);
			else
				throw new AuthenticationException(Label.UnknownSAMAuthenticationError);
		}

		return new authenticateUserResponse(ResponseStatusCodes.SUCCESS, null, sessionKey);
	}

	//Gets the Authentication body from Static resource
	public static String getSAMRequestBodyTemplate(String resourceName) {
		String resourceBody = '';
		StaticResource SAMResource = [Select Body from StaticResource where Name = :resourceName];
		if (SAMResource != null) {
			resourceBody = SAMResource.Body.toString();
		}

		return resourceBody;
	}

	//Status codes available
	public enum ResponseStatusCodes {SUCCESS, FAIL, INCOMPLETESETTINGS}

	//Wrapper class for response messages
	public class authenticateUserResponse {

		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}

		public authenticateUserResponse (ResponseStatusCodes statusCodeIn) {
			statusCode = statusCodeIn;
		}

		public authenticateUserResponse (ResponseStatusCodes statusCodeIn, String messageIn) {
			statusCode = statusCodeIn;
			message = messageIn;
		}

		public authenticateUserResponse (ResponseStatusCodes statusCodeIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			message = messageIn;
			sessionKey = sessionKeyIn;
		}
	}

	public class checkEmailAddressResponse {
		public String guid {get;set;}
		public String status {get;set;}
	}


	//Wrapper class for response messages
	public class bulkUpdateResponse {

		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}

		public bulkUpdateResponse(ResponseStatusCodes statusCodeIn) {
			statusCode = statusCodeIn;
		}

		public bulkUpdateResponse(ResponseStatusCodes statusCodeIn, String messageIn) {
			statusCode = statusCodeIn;
			message = messageIn;
		}
	}

	//wrapper class for user detail response
	public class SamUserDetails {
		public String salutation 	{get;set;}
		public String firstName 	{get;set;}
		public String lastName		{get;set;}
		public String emailAddress	{get;set;}
		public String guid			{get;set;}
	}

 	/***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - wrapper class for registerDigitalUser response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class UpdateUserResponse {
		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}

		public updateUserResponse(ResponseStatusCodes statusCodeIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			message = messageIn;
			sessionKey = sessionKeyIn;
		}
	}

	 /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - wrapper class for registerDigitalUser response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class RegisterDigitalUserResponse {
		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}
		public String accountStatus {get;set;}

		public registerDigitalUserResponse(ResponseStatusCodes statusCodeIn, String accountStatusIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			accountStatus = accountStatusIn;
			message = messageIn;
			sessionKey = sessionKeyIn;
		}
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - wrapper class for alterSalesforceEntitlement response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class AlterSalesforceEntitlementResponse {
		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}

		public alterSalesforceEntitlementResponse(ResponseStatusCodes statusCodeIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			message = messageIn;
			sessionKey = sessionKeyIn;
		}
	}



    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - wrapper class for LostPasswordRequest response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class LostPasswordRequestResponse {
		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}

		public lostPasswordRequestResponse(ResponseStatusCodes statusCodeIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			message = messageIn;
			sessionKey = sessionKeyIn;
		}
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - wrapper class for ResolveIdBySession response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class ResolveIdBySessionResponse {
		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}
		public String guid {get;set;}
		public String pid {get;set;}

		public resolveIdBySessionResponse(ResponseStatusCodes statusCodeIn, String guidIn, String pidIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			message = messageIn;
			guid = guidIn;
			pid = pidIn;
			sessionKey = sessionKeyIn;
		}
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 03/06/2016
    Function - wrapper class for Logoff response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public class LogoffResponse {
		public ResponseStatusCodes statusCode {get;set;}
		public String message {get;set;}
		public String sessionKey {get;set;}

		public logoffResponse(ResponseStatusCodes statusCodeIn, String messageIn, String sessionKeyIn) {
			statusCode = statusCodeIn;
			message = messageIn;
			sessionKey = sessionKeyIn;
		}
	}

	//Custom exceptions
	public class AlterSalesforceEntitlementException extends Exception{}
	public class AuthenticationException extends Exception{}
	public class BulkUpdateException extends Exception{}
	public class CreateAccountException extends Exception{}
	public class UpdateAccountException extends Exception{}
	public class LostPasswordRequestException extends Exception{}
	public class RegisterDigitalUserException extends Exception{}
	public class UpdateUserException extends Exception{}
	public class ResolveIdBySessionException extends Exception{}
	public class LogoffException extends Exception{}
	public class FindUserException extends Exception{}
	public class CheckExistingEmailException extends Exception{}
	public class FetchAllEntitlementsException extends Exception{}
	public class JoinServiceException extends Exception{}
}
