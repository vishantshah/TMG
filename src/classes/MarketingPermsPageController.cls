public with sharing class MarketingPermsPageController {
/* -----------------------------------------------------------------------------------------------------------------------
   Name:        MarketingPermsPageController.cls
   Description:   

   Date        	Version	Author						Summary of Changes 
   -----------	-------	-----------------	------------------------------------------------------------------------------
   Unknown		1.0		Unknown				Initial Release
   14/10/2013	1.1		Chris Yorkston		Moved test classes to MarketingPermsPageControllerTest.cls
   											Increased API version to 28.0
   14/04/2016	1.2		Wiktor Czykin		Modified some getters and setters. Removed different behaviour for Registrants. 
   13/04/2017   1.3     Vishant Shah        Added showMarketingPreferences()
   19/04/2017   1.4     Pawel Chrzanowski   Modified showMarketingPreferences()
------------------------------------------------------------------------------------------------------------------------ */

	Account thisacc, accdetails;
	
	private static final String s2ndEmail = 'TMG_Promo_Email__c';
	private static final String s2ndPhone = 'TMG_Promo_Phone__c';
	private static final String s2ndPost = 'TMG_Promo_Post__c';
	private static final String s2ndSMS = 'TMG_Promo_SMS__c';
	private static final String s3rdEmail = 'TMG_Partner_Promo_Email__c';
	private static final String s3rdPhone = 'TMG_Partner_Promo_Phone__c';
	private static final String s3rdPost = 'TMG_Partner_Promo_Post__c';
	private static final String s3rdSMS = 'TMG_Partner_Promo_SMS__c';
	private static final String LoyEmail = 'TMG_Loyalty_Email__c';
	private static final String LoyPhone = 'TMG_Loyalty_Phone__c';
	private static final String LoyPost = 'TMG_Loyalty_Mail__c';
	private static final String LoySMS = 'TMG_Loyalty_SMS__c';
	
	private static final Integer DEF_YES = 1;
	private static final Integer DEF_NO = 0;

	public Boolean bShowMarketingPreferences {get; set;}

	//oap - allow page to be embedded into existing oap page
	public Constants consts{get;set;}
	
	public Boolean p2ndEmail {
		get {
			if (accdetails.get(s2ndEmail)==null) {accdetails.put(s2ndEmail, DEF_NO);}
			if (accdetails.get(s2ndEmail) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s2ndEmail,1);} else {accdetails.put(s2ndEmail,0);}
		}
	}
	public Boolean p2ndPhone {
		get {
			if (accdetails.get(s2ndPhone)==null) {accdetails.put(s2ndPhone, DEF_NO);}
			if (accdetails.get(s2ndPhone) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s2ndPhone,1);} else {accdetails.put(s2ndPhone,0);}
		}
	}
	public Boolean p2ndPost {
		get {
			if (accdetails.get(s2ndPost)==null) {accdetails.put(s2ndPost, DEF_NO);}
			if (accdetails.get(s2ndPost) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s2ndPost,1);} else {accdetails.put(s2ndPost,0);}
		}
	}
	public Boolean p2ndSMS {
		get {
			if (accdetails.get(s2ndSMS)==null) {accdetails.put(s2ndSMS, DEF_NO);}
			if (accdetails.get(s2ndSMS) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s2ndSMS,1);} else {accdetails.put(s2ndSMS,0);}
		}
	}
	public Boolean p3rdEmail {
		get {
			if (accdetails.get(s3rdEmail)==null) {accdetails.put(s3rdEmail, DEF_NO);}
			if (accdetails.get(s3rdEmail) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s3rdEmail,1);} else {accdetails.put(s3rdEmail,0);}
		}
	}
	public Boolean p3rdPhone {
		get {
			if (accdetails.get(s3rdPhone)==null) {accdetails.put(s3rdPhone, DEF_NO);}
			if (accdetails.get(s3rdPhone) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s3rdPhone,1);} else {accdetails.put(s3rdPhone,0);}
		}
	}
	public Boolean p3rdPost {
		get {
			if (accdetails.get(s3rdPost)==null) {accdetails.put(s3rdPost,DEF_NO);}
			if (accdetails.get(s3rdPost) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s3rdPost,1);} else {accdetails.put(s3rdPost,0);}
		}
	}
	public Boolean p3rdSMS {
		get {
			if (accdetails.get(s3rdSMS)==null) {accdetails.put(s3rdSMS, DEF_NO);}
			if (accdetails.get(s3rdSMS) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(s3rdSMS,1);} else {accdetails.put(s3rdSMS,0);}
		}
	}

	public Boolean pLoyEmail {
		get {
			if (accdetails.get(LoyEmail)==null) {accdetails.put(LoyEmail, DEF_NO);}
			if (accdetails.get(LoyEmail) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(LoyEmail,1);} else {accdetails.put(LoyEmail,0);}
		}
	}

	public Boolean pLoyPhone {
		get {
			if (accdetails.get(LoyPhone)==null) {accdetails.put(LoyPhone, DEF_NO);}
			if (accdetails.get(LoyPhone) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(LoyPhone,1);} else {accdetails.put(LoyPhone,0);}
		}
	}

	public Boolean pLoyPost {
		get {
			if (accdetails.get(LoyPost)==null) {accdetails.put(LoyPost, DEF_NO);}
			if (accdetails.get(LoyPost) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(LoyPost,1);} else {accdetails.put(LoyPost,0);}
		}
	}

	public Boolean pLoySMS {
		get {
			if (accdetails.get(LoySMS)==null) {accdetails.put(LoySMS, DEF_NO);}
			if (accdetails.get(LoySMS) == 1) {return true;} else {return false;}
		}
		set {
			if (value == true) {accdetails.put(LoySMS,1);} else {accdetails.put(LoySMS,0);}
		}
	}
	
	public Boolean doNotContact {
		get {
			return accdetails.Do_Not_Contact__pc;
		}
		set {
			if (value==true) {
				this.p2ndemail = false;
				this.p2ndphone = false;
				this.p2ndpost = false;
				this.p2ndSMS = false;
				this.p3rdemail = false;
				this.p3rdphone = false;
				this.p3rdpost = false;
				this.p3rdSMS = false;
				this.pLoyEmail = false;
				this.pLoyPost = false;
				this.pLoyPhone = false;
				this.pLoySMS = false;
				accdetails.Do_Not_Contact__pc = true;
			} else {
				accdetails.Do_Not_Contact__pc = false;
			}
		}
	}

	/***************************************************************************************
	Developer - Vishant Shah
	Date - 13/04/2017
	Version - 1.0
	Function - determine Marketing Preferences visibiliy based on Custom Settings
	#############Change Log#############
	Modified by        Version     Change Date
	Pawel Chrzanowski  1.1         19/04/2017  fixed logic
	****************************************************************************************/
	private Boolean showMarketingPreferences(){
		Application_Settings__c setting = Application_Settings__c.getInstance(Constants.PROFILES_FOR_MARKETING_PREFERENCES);

		if(setting != null && String.isNotBlank(setting.Value__c)){
			User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
			if(setting.Value__c.toUpperCase().contains(currentUser.Profile.Name.toUpperCase())){
				return true;
			}
		}
		return false;
	}
	
	public String lastUpdateDate {
		get {
			if (accdetails.Permissions_Last_Change_Date__c != null) {
					
				return accdetails.Permissions_Last_Change_Date__c.format();
			} else {return null;}
		}
		
	}
	
	public MarketingPermsPageController (Apexpages.Standardcontroller controller) {
		this.thisacc = (Account)controller.getRecord();

		//oap - return prop to default to ensure any other process using this page displays the header
		Constants.displayHeaderCustomSinglePayment = true;
		requery();
	}
	
	public void savePerms() {
		accdetails.Permissions_Last_Change_Date__c = System.today();
		System.debug('accdetails1:'+accdetails);
		update accdetails;
		requery();
		System.debug('accdetails2:'+accdetails);
	}
	
	public void doNotContact() {
		accdetails.Permissions_Last_Change_Date__c = System.today();
		update accdetails;
		requery();
	}
	
	public void requery() {
		accdetails = [Select a.Id,a.RecordTypeId, a.Permissions_Last_Change_Date__c, a.TMG_Promo_SMS__c, a.TMG_Promo_Post__c, a.TMG_Promo_Phone__c, a.TMG_Promo_Email__c, 
		a.TMG_Partner_Promo_SMS__c, a.TMG_Partner_Promo_Post__c, a.TMG_Partner_Promo_Phone__c, a.TMG_Partner_Promo_Email__c, 
		a.TMG_Loyalty_SMS__c, a.TMG_Loyalty_Phone__c, a.TMG_Loyalty_Mail__c, a.TMG_Loyalty_Email__c, a.Do_Not_Contact__pc From Account a
		where a.Id = :thisacc.Id];

		if (bShowMarketingPreferences == null){
			bShowMarketingPreferences = showMarketingPreferences();
		}
	}
}