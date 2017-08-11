/**
* Author:       Michal Kwika
* Date:         05/08/2015
* Description:  API calls to check email in SAM
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika	10/08/2015
* Michal Kwika	01/09/2015
* Michal Kwika	24/11/2015
* Gavin Palmer 	22/06/2016 // modified save()
**/
public with sharing class Account_UpdateEmailWithCalloutsCtrl {
	private ApexPages.StandardController stdCon;
	private final Account acc;
	public Integer emailSAMCounter;

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/08/2015
	Function    Main constructor
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public Account_UpdateEmailWithCalloutsCtrl(ApexPages.StandardController con) {
		this.stdCon = con;
		this.acc = (Account)con.getRecord();
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/08/2015
	Function    Save action
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			01/09/2015
	Gavin Palmer      	1.2 		22/06/2016 // modified core api callout to non static method
	****************************************************************************************/
	public PageReference save() {
		PageReference url = null;

		try {
//Check Email in Salesforce first
			if (string.isempty(acc.PersonEmail)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Email));
				return url;
			}

			if (!String.isEmpty(acc.PersonEmail)) {
//trim the email
				acc.PersonEmail = acc.PersonEmail.trim();
				List <Account> lAccountsWithGivenEmail = AccountUtility.findAccounts('', '', acc.PersonEmail, '');
				if (lAccountsWithGivenEmail.size() > 0) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Other_Account_Exist));
					return url;
				}

//check the email format
				Pattern emailPattern = Pattern.compile(Constants.REG_UPDATED_EMAIL_FORMAT);
				Matcher emailMatcher = emailPattern.matcher(acc.PersonEmail);

				if (!emailMatcher.matches()) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Format_Error));
					return null;
				}
			}

			Map <Integer, String> mResponseWithId = new Map <Integer, String>();
			if (!Test.isRunningTest()) {
				boolean callCoreApi = boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).value__c);
				if (callCoreApi) {
					CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
					mResponseWithId = calloutUtility.getNumOfEmailsInSAM(acc.PersonEmail);
					System.debug('### LOG map from SAM: ' + mResponseWithId);
				}
			}
// check value - if counter is set to -1; then there is no connection to SAM
			if (mResponseWithId.containsKey(-1)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Message));
				return null;
			} else if (mResponseWithId.containsKey(0)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Other_Account_Exist_In_SAM));
				return null;
			} else {
				updateAccountEmail(acc.Id, acc.PersonEmail);
				url = stdCon.view();
				url.setRedirect(true);
			}
		} catch (System.Exception e) {
			ApexPages.addMessages(e);
			System.debug('### Account_UpdateEmailWithCalloutsCtrl ex:' + e.getMessage());
		}

		return url;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/08/2015
	Function    Helper method to update SF Account
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika	1.1	10/08/2015
	****************************************************************************************/
	public static void updateAccountEmail(String id, String email) {
		Account acc = [SELECT Id, PersonEmail FROM Account WHERE Id = :id];
		acc.PersonEmail = email;

		update acc;
	}
}