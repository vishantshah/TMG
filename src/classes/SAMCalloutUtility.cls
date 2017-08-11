/**
* Author:       Sally ElGhoul (Tquila)
* Date:         16/04/2015
* Description:  A utility class for SAM callouts
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
global class SAMCalloutUtility {
	
	//Constant Values
	public static final string RESET_PASSWORD_ERROR_MESSAGE		= 'We cannot send a reset password at this time. Please try later';
	public static final string RESET_PASSWORD_SUCCESS_MESSAGE	= 'Request successful. An email will be sent to the customer with password reset details';
	public static final string RESET_PASSWORD_REQUEST_URL		= '/profiles/passwordreset/{0}'; //profiles/passwordreset/{emailAddress}
	public static final string SAM_ENDPOINT_NAME				= 'SAMEndPoint';
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        16/04/2015
    Function    Call SAM Reset Password
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	webService static string ResetPassword(String emailValue) {
		try {
			//Prepare the Endpoint to be called
			string FullRequestURL=SAMHTTPSettings__c.getInstance(SAM_ENDPOINT_NAME).value__c;  
			FullRequestURL+=string.format(RESET_PASSWORD_REQUEST_URL,new list<string>{emailValue});
			
			//Call Sam Endpoint
			HttpRequest req = new HttpRequest();
			req.setEndpoint(FullRequestURL);
			req.setMethod('GET');
			Http http = new Http();
			HTTPResponse res = http.send(req);
			
			//Access the body for the result
			System.debug(res.getBody());
			
			//Reset password sent successfully
			return RESET_PASSWORD_SUCCESS_MESSAGE;
			
		} catch(Exception ex){
			system.debug('Error occured to reset Sam Password password (SAMCalloutUtility class, function ResetPassword): '+ex.getMessage()+' Line Number : '+ex.getLineNumber());
			return RESET_PASSWORD_ERROR_MESSAGE;
		}
		return null;
	} 
}