/**
* Author:       Michal Kwika (Accenture)
* Date:         15/12/2015
* Description:  this class is the cnotroller of the page OutboundDigitalAcquisition page
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika		14/01/2016
* Michal Szewczyk   28/01/2016	added validation for title and given name 
* Michal Kwika		17/02/2016	added new value for Quote outbound
* Michal Kwika		25/02/2016	set Phone fields to non-required
* Wiktor Czykin		11/03/2016	modified constructor and getAccountValidToRegisterOrConvert()
* Wiktor Czykin		17/05/2017	modified one constant to label
* */

public class OutboundDigitalAcquisitionCtrl {

	public Account newAccountObj        {get; set;}
	public Contact newContactObj		{get; set;}
	public boolean isAccountOptIn       {get; set;}
	public String strSelectedAccountId  {get; set;}
	public Boolean showNewAccoountForm  {get; set;}
	private Id tmgWebApiProfileId       {get; set;}
	private zqu__Quote__c newQuoteObj	{get; set;}
	public 	POC__c pocObj				{get; set;}
	/* URL Parameters */
	private String selectedProduct 		{get; set;}
	private String orderMethod			{get; set;}
	private String pocId				{get; set;}
	private String payFreq				{get; set;}
	private Double startPeriods			{get; set;}
	private Double startPrice			{get; set;}
	private Double subseqPrice			{get; set;}
	private String emadd       			{get; set;}
	/* Controlling buttons */
	public Boolean isNewAccountOption	{get; set;}
	public Boolean isConvertOption		{get; set;}
	public Boolean isUpdateOption		{get; set;}
	/* Email on Account changes*/
	public Boolean isEmailChanged		{get; set;}
	public String oldAccountEmail		{get; set;}
	/*Zuora API*/
	private Zuora.zApi zapi = new Zuora.zApi();


	//get the registrant record type id
	public String registrantRecordTypeId {
		get{
			return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		}
	}
	//get if the Title is required
	public boolean isTitleRequired {
		get{
			if (newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
				return true;
			}
			return false;
		} set;
	}

	//get if State is required
	public boolean isStateRequired {
		get{
			if (newAccountObj.PersonMailingCountry == Constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || newAccountObj.PersonMailingCountry == Constants.COUNTRY_CANADA_TWO_LETTERS_CODE) {
				return true;
			}
			return false;
		} set;
	}

	//get if the postal code is required
	public boolean isPostalCodeRequired {
		get{
			if (newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
				return true;
			}
			return false;
		} set;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    Constructor
	******************* Change Log *******************
	Modified by         Version     Change Date
	Wiktor Czykin		1.1			11/03/2016	//added -2 type of status handling
	****************************************************************************************/
	public OutboundDigitalAcquisitionCtrl() {
		//show the form
		this.showNewAccoountForm = true;
		this.isAccountOptIn = false;
		//with new option
		this.isNewAccountOption = true;
		this.isConvertOption = false;
		this.isUpdateOption = false;
		this.isEmailChanged = false;

		//Initialize the account
		if (newAccountObj == null) {
			newAccountObj = new Account();
			newAccountObj.PersonMailingCountry = Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE;
		}
		//for all account recordtypeId should be registrant
		newAccountObj.RecordTypeId = registrantRecordTypeId;

		//initialize the contact object
		//I am using the contact object because the input field didn't appear on the page for the salutation and first name when I used the account
		if (newContactObj == null) {
			newContactObj = new Contact();
		}

		//check parameters
		if (areSynthesisParametersCorrect()) {
			//query POC object
			this.pocObj = getPOC(this.pocId);

			if (this.pocObj != null) {
				//check if poc was already used
				if (this.pocObj.Subscription_Acquired__c) {
					AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Offer_Code_Used);
					this.showNewAccoountForm = false;
					this.isNewAccountOption = false;
					return;
				}

				//else get Account if exists in SF
				Map <Integer, Account> mAccountWithDecisionCode;
				if (this.emadd != null) {
					mAccountWithDecisionCode = getAccountValidToRegisterOrConvert(this.emadd, pocObj.Subscriber_Number__c);
					if (!this.emadd.equalsIgnoreCase(pocObj.Email__c)) {
						this.isEmailChanged = true;
						this.oldAccountEmail = pocObj.Email__c;
					}
				} else if (this.emadd == null && pocObj.Email__c == null && pocObj.Subscriber_Number__c == null) {

					/* THIS IS PART WHEN WE DON'T HAVE DATA ON POC - progress or stop? */
					//fill form with values for new account - new Acccount scenario
					newAccountObj = fillValuesForAccountFromPOC(this.pocObj);
				} else if (this.emadd == null || mAccountWithDecisionCode == null) {
					mAccountWithDecisionCode = getAccountValidToRegisterOrConvert(pocObj.Email__c, pocObj.Subscriber_Number__c);
				}

				System.debug('### OutboundDigitalAcquisitionCtrl: mapAccount: ' + mAccountWithDecisionCode);
				if (mAccountWithDecisionCode == null) {
					//fill form with values for new account - new Acccount scenario
					newAccountObj = fillValuesForAccountFromPOC(this.pocObj);
				} else if(mAccountWithDecisionCode.containsKey(-2)){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Outbound_Digital_Acquisition_More_than_1_account));
					this.showNewAccoountForm = false;
					this.isNewAccountOption = false;
					return;
				} else if (mAccountWithDecisionCode.containsKey(-1)) {
					//has Active subscritption
					if (!AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Account_Has_Active_Sub)) {
						this.showNewAccoountForm = false;
						this.isNewAccountOption = false;
						return;
					}
				} else if (mAccountWithDecisionCode.containsKey(0)) {
					//update current Account - is registrant without active sub
					//if email exists - just show the difference
					this.isNewAccountOption = false;
					this.isUpdateOption = true;
					newAccountObj = mAccountWithDecisionCode.get(0);
					//fill form with Salutation
					newContactObj.FirstName = newAccountObj.FirstName;
					newContactObj.Salutation = newAccountObj.Salutation;

				} else if (mAccountWithDecisionCode.containsKey(1)) {
					//convert to Registrant
					this.isNewAccountOption = false;
					this.isConvertOption = true;
					newAccountObj = mAccountWithDecisionCode.get(1);
					newAccountObj.RecordTypeId = this.registrantRecordTypeId;
					newContactObj.FirstName = newAccountObj.FirstName;
					newContactObj.Salutation = newAccountObj.Salutation;
				}

				//create and show information message
				String frequency = (this.payFreq.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER)) ? Constants.OUTBOUND_ANNUAL_BILLING_PERIOD : Constants.OUTBOUND_MONTHLY_BILLING_PERIOD;
				String infoMsg = Label.Outbound_Digital_Acquisition_Info_About_Product + ' <b>' + this.selectedProduct + ' ' + frequency + '</b>';
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, infoMsg));

				//another message if Account exist in SF
				if (this.isConvertOption || this.isUpdateOption) {
					String ahref = '<a href="' + '/' + newAccountObj.Id + '">GO TO ACCOUNT PAGE</a>.';
					String accountExists = Label.Outbound_Digital_Acquisition_Info_About_Account + ahref;
					ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.CONFIRM, accountExists);
					ApexPages.addMessage(myMsg2);
				}

			}

			else {
				if (!AccountUtility.isValidEmptyString('', Label.Offline_Acquisition_POC_not_found)) {
					this.showNewAccoountForm = false;
					this.isNewAccountOption = false;
					return;
				}
			}
		}

		else {
			this.showNewAccoountForm = false;
			this.isNewAccountOption = false;
		}

	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    This method used to map parameters
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			14/01/2016
	****************************************************************************************/
	public Boolean areSynthesisParametersCorrect() {

		Map<String, String> mapParameters = Apexpages.currentPage().getParameters();
		System.debug('### OutboundDigitalAcquisitionCtrl: parameters ' + mapParameters);
		this.orderMethod = mapParameters.get('OrderMethod');
		this.selectedProduct = mapParameters.get('selectedProduct');
		this.pocId = mapParameters.get('pocid');
		this.payFreq = mapParameters.get('PayFreq');
		this.emadd = mapParameters.get('EMADD');
		//assign numbers from URL
		try {
			if (mapParameters.containsKey('StartPeriods')) {
				this.startPeriods = Decimal.valueOf(mapParameters.get('StartPeriods'));
			}
			if (mapParameters.containsKey('StartPrice')) {
				this.startPrice = Decimal.valueOf(mapParameters.get('StartPrice'));
			}
			if (mapParameters.containsKey('SubseqPrice')) {
				this.subseqPrice = Decimal.valueOf(mapParameters.get('SubseqPrice'));
			}

		} catch (Exception ex) {
			AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Page_MissingURL_Type_PriceNumeric);
			System.debug('### OutboundDigitalAcquisitionCtrl Exception: ' + ex);
			return false;
		}

		if (!AccountUtility.isValidEmptyString(this.pocId, Label.Offline_Acquisition_POC_code_not_in_URL)) {
			return false;
		}

		if (!AccountUtility.isValidEmptyString(this.selectedProduct, Label.Outbound_Digital_Acquisition_Page_MissingURL_Parameter_SelectedProduct)) {
			return false;
		}

		if (!AccountUtility.isValidEmptyString(this.payFreq, Label.Outbound_Digital_Acquisition_Page_MissingURL_Parameter_PayFreq)) {
			return false;
		}

		if (!this.payFreq.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER) && !this.payFreq.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER)) {
			AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongFrequency);
			return false;
		}

		if (this.startPeriods == null && this.payFreq.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER)) {
			AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongStartM);
			return false;
		}

		if (!this.selectedProduct.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET) && !this.selectedProduct.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE)) {
			AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongProduct);
			return false;
		}

		if (this.payFreq.toLowerCase().equalsIgnoreCase(Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER) && this.startPeriods != null && (this.subseqPrice == null && this.startPrice == null)) {
			AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongStartPeriodComboPrice);
			return false;
		}

		if (this.pocObj != null && this.pocObj.TCodeManagement__c == null) {
			AccountUtility.isValidEmptyString('', Label.Outbound_Digital_Acquisition_Offer_Code_Without_Tcode);
			return false;
		}
		return true;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    This method used to create a quote in SF and redirect to next step of
				acquisition if there is no issue
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public POC__c getPOC(String pocId) {
		List <POC__c> lObjsPOC = new List<POC__c>();
		lObjsPOC = [select Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, Street__c, Street_Address_Line_2__c, TCodeManagement__c, title__c, MobileTelephone__c, HomeTelephone__c, WorkTelehone__c, Subscription_Acquired__c
		            from POC__c where POC_ID__c = :pocId];

		if (lObjsPOC.size() > 0) {
			System.debug('### OutboundDigitalAcquisitionCtrl: FOUND POCs: ' + lObjsPOC);
			return lObjsPOC.get(0);
		}

		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    This method used to create a quote in SF and redirect to next step of
				acquisition if there is no issue
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference createQuoteAndGoToNextStep() {
		try {
			//we need TS Number, which is formula+autonumber
			Account acc = [SELECT Subscriber_Number__c FROM Account WHERE Id = :strSelectedAccountId];

			this.newQuoteObj = fillValuesForQuoteObj(acc);
			insert newQuoteObj;

			PageReference prZuoraOutboundPage = Page.zuora_outbound_selectProducts;
			prZuoraOutboundPage.getParameters().put('id', newQuoteObj.Id);
			prZuoraOutboundPage.setRedirect(true);

			return prZuoraOutboundPage;

		} catch (Exception ex) {
			ApexPages.addMessages(ex);
			System.debug('### OutboundDigitalAcquisitionCtrl Exception: ' + ex);
		}

		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    Method used to map all properties to Quote Object
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			14/01/2016
	Michal Kwika		1.2			17/02/2016 - added Outbound origin always as Outbound
	****************************************************************************************/
	private zqu__Quote__c fillValuesForQuoteObj(Account acc) {
		//get default values for quote first
		zqu__Quote__c tempQuoteObj = ZuoraQuote_Utility.createZuoraQuote(this.zapi, acc, Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE, null);

		tempQuoteObj.Outbound_Selected_Product__c = this.selectedProduct;
		tempQuoteObj.Subscription_Origin__c = Constants.DIRECTION_OUTBOUND;
		tempQuoteObj.Outbound_POC__c = this.pocObj.Id;
		tempQuoteObj.Outbound_Payment_Frequency__c = this.payFreq;
		tempQuoteObj.Tcode__c = this.pocObj.TCodeManagement__c;

		if (this.emadd != null) {
			tempQuoteObj.Outbound_Customer_Email__c = this.emadd;
		}

		if (this.startPeriods != null) {
			tempQuoteObj.Outbound_Start_Periods__c = this.startPeriods;
		}

		if (this.startPrice != null) {
			tempQuoteObj.Outbound_Start_Price__c = this.startPrice;
		}
		if (this.subseqPrice != null) {
			tempQuoteObj.Outbound_Subsequent_Price__c = this.subseqPrice;
		}

		return tempQuoteObj;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    Method used to map all properties to Account Object
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public Account fillValuesForAccountFromPOC(POC__c pocObj) {
		//title or salutation?
		if (CoreAPICalloutUtility.checkIfSalutation(pocObj.title__c)) {
			newAccountObj.Salutation = pocObj.title__c;
			newContactObj.Salutation = pocObj.title__c;
		} else {
			newAccountObj.Title__c = pocObj.title__c;
		}
		//copy value for the object and to show on form
		newAccountObj.FirstName = pocObj.FirstName__c;
		newContactObj.FirstName = pocObj.FirstName__c;
		newAccountObj.LastName = pocObj.LastName__c;
		newAccountObj.PersonMailingState = pocObj.State__c;
		newAccountObj.PersonMailingCity = pocObj.City__c;
		newAccountObj.PersonMailingStreet = pocObj.Street__c;
		newAccountObj.PersonMailingPostalCode = pocObj.PostalCode__c;

		//if there is no email in URL insert email from POC
		if (String.isEmpty(this.emadd)) {
			newAccountObj.PersonEmail = pocObj.Email__c;
		} else {
			newAccountObj.PersonEmail = this.emadd;
		}

		//we assume that Country is always UK now
		newAccountObj.PersonMailingCountry = Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE;

		//insert phone numbers if they are available in POC object
		if (String.isNotEmpty(pocObj.HomeTelephone__c)) {
			newAccountObj.PersonHomePhone = pocObj.HomeTelephone__c;
		} else if (String.isEmpty(pocObj.HomeTelephone__c) && String.isNotEmpty(pocObj.WorkTelehone__c)) {
			newAccountObj.PersonHomePhone = pocObj.WorkTelehone__c;
		}

		if (String.isNotEmpty(pocObj.MobileTelephone__c)) {
			newAccountObj.PersonMobilePhone = pocObj.MobileTelephone__c;
		}

		return newAccountObj;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        29/12/2015
	Function    Method used to check Account in SF
	******************* Change Log *******************
	Modified by         Version     Change Date
	Wiktor Czykin		1.1			11/03/2016	//added -2 error
	****************************************************************************************/
	public Map <Integer, Account> getAccountValidToRegisterOrConvert(String emailToSearch, String tsNumber) {
		Map <Integer, Account> mAccountToUpdate = new Map <Integer, Account>();
		List <Account> lAccountsInSF = new List<Account>();
		//find accounts based on email
		//Assumption: there is only one Account with the same email address!!!
		if (String.isNotEmpty(tsNumber)) {
			lAccountsInSF = AccountUtility.findAccounts('', '', '', tsNumber);
		}
		if (lAccountsInSF.isEmpty()) {
			lAccountsInSF = AccountUtility.findAccounts('', '', emailToSearch, '');
		}
		if (lAccountsInSF.size() > 1){
			mAccountToUpdate.put(-2, null);
			return mAccountToUpdate;
		} else if (lAccountsInSF.size() == 1) {
			//check if account has active Sub
			String  sActiveCheck = AccountUtility.hasAccountActiveSub(lAccountsInSF.get(0)); 
			if (sActiveCheck != AccountUtility.STATUS_ACTIVE) {
				List<Account> lRegistrants = AccountUtility.getRegistrantAccounts(lAccountsInSF);
				List<Account> lNonRegistrants = AccountUtility.getNonRegistrantAccounts(lAccountsInSF);

				if (lRegistrants.size() > 0) {
					//if registrant - update account
					mAccountToUpdate.put(0, lRegistrants.get(0));
					return mAccountToUpdate;

				} else if (lNonRegistrants.size() > 0) {
					//if old world convert to registrant
					mAccountToUpdate.put(1, lNonRegistrants.get(0));
					return mAccountToUpdate;
				}
			} else {
				mAccountToUpdate.put(-1, null);
				return mAccountToUpdate;
			}
		}
		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        17/12/2015
	Function    Method used to save Account to DB
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			25/02/2016 - set Phone fields to non-required
	****************************************************************************************/
	public Boolean isAccountValidToSave() {

		return AccountUtility.isPersonAccountFullyValid(newAccountObj, newContactObj, this.isNewAccountOption, false);
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    Method used to save Account to DB
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference saveNewAccount() {

		try {
			//first we shhould validate that the user entered all the mandatory fields
			if (isAccountValidToSave()) {

				newAccountObj.Salutation = newContactObj.Salutation;
				newAccountObj.FirstName  = newContactObj.FirstName;
				//newAccountObj.LastName   = newContactObj.LastName;
				System.debug('### Save New Account: aacc: before insert' + newAccountObj);
				//if the opt in checkbox is checked we need to check the two marketing preferences of 2nd party (email and post)
				if (isAccountOptIn) {
					newAccountObj.isNewAccountOptIn__c = true;
				}

				//insert new account
				insert newAccountObj;
				this.strSelectedAccountId = newAccountObj.Id;

				return createQuoteAndGoToNextStep();
			}
		} catch (DmlException ex) {
			ApexPages.addMessages(ex);
		} 
		catch (exception ex) {
			System.debug('### OutboundDigitalAcquisitionCtrl Exception: ' + ex);
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error);
			ApexPages.addMessage(myMsg);
		}
		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        30/12/2015
	Function    this function is called to update/convert Account
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference updateOrConvertAccount() {
		try {
			//first we shhould validate that the user entered all the mandatory fields
			if (isAccountValidToSave()) {
				System.debug('### isConvertOption? - ' + isConvertOption);
				//change RT to Registrant and set that this Account was converted
				if (this.isConvertOption) {
					newAccountObj.Converted_Account__c = RecordTypeUtility.getRecordTypeName(Account.SObjectType, newAccountObj.RecordTypeId, Account.class.getName());
					//newAccountObj.Converted_Account__c = newAccountObj.RecordType.Name;
				}
				newAccountObj.Salutation = newContactObj.Salutation;
				newAccountObj.FirstName  = newContactObj.FirstName;

				//if the opt in checkbox is checked we need to check the two marketing preferences of 2nd party (email and post)
				if (isAccountOptIn) {
					newAccountObj.isNewAccountOptIn__c = true;
				}
				//insert new account
				update newAccountObj;

				if (this.isConvertOption) {
					//insert Account intoSAM
					boolean callCoreApi = boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).value__c);
					if (callCoreApi) {
						AccountUtility.setTMGwebAPIprofileId(this.tmgWebApiProfileId);
						if (UserInfo.getProfileId() != this.tmgWebApiProfileId) {
							CoreAPICalloutUtility.SendObjectEvent(Constants.NEW_RECORD_CREATED_ACTION_NAME, Account.class.getName(), newAccountObj.id);
						}
					}
				}

				//redirect the user to the quote wizard creation page
				this.strSelectedAccountId = newAccountObj.id;
				return createQuoteAndGoToNextStep();
			}
		} catch (exception ex) {
			System.debug('### OutboundDigitalAcquisitionCtrl Exception: ' + ex);
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error); ApexPages.addMessage(myMsg);
		}
		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    this function is called to refresh the UI
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference RefreshUI() {
		newAccountObj.PersonMailingState = '';
		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        7/11/2015
	Function    this function is called to get the list of countries
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public List<SelectOption> getStates() {
		List<SelectOption> liOptions = new List<SelectOption>();
		liOptions.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		for (State_Codes__c stateObj : [SELECT State_Name__c, Name FROM State_Codes__c where Country_Code__c = :newAccountObj.PersonMailingCountry ORDER BY Display_Order__c, State_Name__c ASC]) {
			liOptions.add(new SelectOption(stateObj.Name, stateObj.State_Name__c));
		}
		return liOptions;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        7/11/2015
	Function    this function is called to get the list of countries
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public List<SelectOption> getCountries() {
		List<SelectOption> liOptions = new List<SelectOption>();
		liOptions.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
		for (Country_Codes__c country : [SELECT name, Country_Name__c FROM Country_Codes__c ORDER BY Display_Order__c, Country_Name__c ASC]) {
			liOptions.add(new SelectOption(country.name, country.Country_Name__c));
		}
		return liOptions;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        15/12/2015
	Function    this function is called to close the browser tba (special page invoked)
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference closeTab() {
		PageReference pr = Page.CloseMe;
		pr.setRedirect(true);
		return pr;
	}
	
}