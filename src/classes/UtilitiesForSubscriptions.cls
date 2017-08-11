/**
* @author Unknown
* @date Unknown
* @description helper class
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         08/2015  	//getRetailerAcc(),getRetailerFromRETID(),changed signature/name from returnSelectedRetailerID() to returnSelectedRetailerWithoutError()
Wiktor Czykin 	1.2 		21/10/2015	//modified returnSelectedRetailerWithoutError(), returnSelectedRetailerID()
Wiktor Czykin	1.3			12/11/2016	//removed unsused code
Wiktor Czykin	1.4			04/2016		//nothing actually change, minor class clean-up
Gavin Palmer 	1.5 		17/06/2016  //modified copyPOCToAccount()
Wiktor Czykin   1.6         19/07/2016  //modified copyPOCToAccount()
Wiktor Czykin	1.7			06/09/2016	//modified fastRetrieveRetailers()
Wiktor Czykin   1.8			04/11/2016  //modified copyPOCToAccount()
**/
public class UtilitiesForSubscriptions {

	public List<Account> activeRetailerAccounts;
	public ActiveRetailers newActiveRetailers;
	public List<ActiveRetailers> allActiveRetailers;
	public String agencyIdentifier{get;Set;}

	//* Restriction to incentives
	public Boolean restrictTo52Week{get;set;}
	public Boolean restrictionToDDOnly{get;set;}
	public Boolean restrictionToCCOnly{get;set;}

	//* Special Open Offer Incentives
	public String selectedIncentiveSelection{get;Set;}

	//Retailers
	public Map<ID,integer> hndRetailers;
	public Map<ID,Account> activeRetailerDetails;
	public Boolean displayRetailers{get;set;}

	public Boolean SetEmail{get;set;}
	public String DefaultAgencyEmail;

	public static Integer convertBooleanToInteger(Boolean Pref){
		Integer returnValue;
		if(Pref == true) returnValue = 1; Else returnValue = 0;

		return returnValue;
	}

	public void getRetailer(String PostcodeRetailSearch, Boolean GetActiveRetailers){
		//OAP - Return retailers with active Subscribers
		//get all active distinct retailers into a Map
		try{
			String Postcode;
			list<Subscription__c> ActiveHNDSubs;
			if (!(PostcodeRetailSearch == '' || PostcodeRetailSearch == null)){
				Postcode = formatPostCode(PostcodeRetailSearch);
				if (Postcode == '')//incomplete postcode provided so set to original entry
					Postcode = PostcodeRetailSearch;

				Date dt = date.Today();
				ActiveHNDSubs = Database.query('Select Retailer__c from Subscription__c where Retailer__r.BillingPostalCode Like \'' + Postcode + '%\' and Retailer__c != null and Delivery_Type__c=\'HND\' and ((Subscription_Status__c = \'Active\' or Subscription_Status__c = \'In Renewal\' )  or (Subscription_Status__c = \'Pending Cancellation\' and Cancellation_Date__c>:dt)) limit 1000');
			}

			Set<ID> ActiveHNDSubIDs = new Set<ID>();
			for (Subscription__c eachsub: ActiveHNDSubs)
				ActiveHNDSubIDs.add(eachsub.Retailer__c);

			//get Account details of all active retailers from Set above
			if (GetActiveRetailers){
				activeRetailerAccounts = [Select a.id, a.Name, a.BillingStreet, a.BillingCity, a.BillingState, a.BillingPostalCode, a.Retmulti__c, a.RET_ID__c, a.Shop_Name__c, Manager__c, a.phone  from Account a where a.id In :ActiveHNDSubIDs Order By a.BillingPostalCode limit 1000];
				activeRetailerDetails = new Map<ID,Account>([Select a.id, a.Name, a.BillingStreet, a.BillingCity, a.BillingState, a.BillingPostalCode, a.Retmulti__c, a.RET_ID__c, a.Shop_Name__c, Manager__c, a.phone  from Account a where a.id In :ActiveHNDSubIDs Order By a.BillingPostalCode limit 1000]);
			}else{
				Id retailerID = UtilityLookupSubscriptionVariables.getRecordType('Retailer Account');
				activeRetailerAccounts = Database.query('Select a.id, a.Name, a.BillingStreet, a.BillingCity, a.BillingState, a.BillingPostalCode, a.Retmulti__c, a.RET_ID__c, a.Shop_Name__c, Manager__c, a.phone from Account a where a.BillingPostalCode Like \'' + Postcode + '%\' and a.RecordTypeID= \'' + retailerID + '\' Order By a.BillingPostalCode limit 1000');
				activeRetailerDetails = new Map<ID,Account>((list<Account>)Database.query('Select a.id, a.Name, a.BillingStreet, a.BillingCity, a.BillingState, a.BillingPostalCode, a.Retmulti__c, a.RET_ID__c, a.Shop_Name__c, Manager__c, a.phone from Account a where a.BillingPostalCode Like \'' + Postcode + '%\' and a.RecordTypeID= \'' + retailerID + '\' Order By a.BillingPostalCode limit 1000'));
			}
			hndRetailers = new Map<ID,integer>();
			integer HNDRetailerCount=0;

			//gets the number of active Subs with each retailer
			for (Subscription__c EachSub : ActiveHNDSubs){
				HNDRetailerCount = hndRetailers.get(EachSub.Retailer__c);
				system.debug('EachSub ' + EachSub + ' ' + HNDRetailerCount);
				if (HNDRetailerCount == null )//checks if the retailer has already been added to the Map
					hndRetailers.put(EachSub.Retailer__c,1);
				else
					hndRetailers.put(EachSub.Retailer__c,HNDRetailerCount + 1);
			}
		}catch(Exception e){
			system.debug(e);
		}
		System.debug('### getRetailer - ACTIVE_RETAILER_ACCOUNTS: ' + activeRetailerAccounts);
		System.debug('### getRetailer - ACTIVE_RETAILER_DETAILS: ' + activeRetailerDetails);
	}

	/***************************************************************************************
	Developer - Unknown
	Date - Unknown
	Version - 1.2
	Function - Fetch and map retailers to wrappers
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			12/01/2016	//removed unused code, moved allActiveRetailers and displayRetailers outside if to prevent exceptions in callers
	Wiktor Czykin	1.2			06/09/2016	//small formatting change
	****************************************************************************************/
	public void fastRetrieveRetailers(String postcodeRetailSearch, Boolean getActiveRetailers){
		try{
			String Postcode;
			if (String.isNotBlank(postcodeRetailSearch)){
				Postcode = formatPostCode(postcodeRetailSearch);
				if (Postcode == '')//incomplete postcode provided so set to original entry
					Postcode = postcodeRetailSearch;

				Id retailerID = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_ACCOUNT_RETAILER, Account.class.getName());
				String sQueryBase = 'select Id, Retailer_Active_Sub_Count__c, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, Retmulti__c, RET_ID__c, Shop_Name__c, Manager__c, Phone from Account';
				String sQuery;
				if (getActiveRetailers){
					sQuery = sQueryBase+' where BillingPostalCode like \'' + Postcode + '%\' and Retailer_Active_Sub_Count__c > 0 and RecordTypeID= \'' + retailerID + '\' order by BillingPostalCode limit 100';
					activeRetailerDetails = new Map<Id, Account>((List<Account>)Database.query(sQuery));
				}else{
					sQuery = sQueryBase+' where BillingPostalCode like \'' + Postcode + '%\' and RecordTypeID= \'' + retailerID + '\' order by BillingPostalCode limit 100';
					activeRetailerDetails = new Map<Id, Account>((List<Account>)Database.query(sQuery));
				}
				System.debug('TMGLOG::UtilitiesForSubscriptions:fastRetrieveRetailers:query='+sQuery);
				System.debug('TMGLOG::UtilitiesForSubscriptions:fastRetrieveRetailers:recordsReturned='+activeRetailerDetails.size());
				this.allActiveRetailers = new List<ActiveRetailers>();
				this.displayRetailers =  false;
				if (activeRetailerDetails.size() > 0){
					displayRetailers =  true; //display results
					for (Account retailer: activeRetailerDetails.Values()){
						newActiveRetailers = new ActiveRetailers();
						newActiveRetailers.ValidSubsCount = Integer.valueof(retailer.Retailer_Active_Sub_Count__c);
						newActiveRetailers.Retailer = retailer;
						allActiveRetailers.add(newActiveRetailers);
					}
				}
			}
		}catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'An error occurred. No retailers exist.'));
			System.debug(e);
		}
	}

	public void retrieveRetailers(String PostcodeRetailSearch, Boolean GetActiveRetailers){
		String RetailerDetails;
		Account EachAcc;
		system.debug('Start RetrieveRetailers ');
		try{
			getRetailer(PostcodeRetailSearch,GetActiveRetailers);

			system.debug('ActiveRetailerDetails ' + activeRetailerDetails);

			if (activeRetailerDetails.size() >0 ){
				Integer posInList;
				allActiveRetailers = new list<ActiveRetailers>();
				displayRetailers =  true; //display results
				for (ID RetailerID: activeRetailerDetails.keyset()){
					newActiveRetailers = new ActiveRetailers();
					EachAcc = activeRetailerDetails.get(RetailerID);
					newActiveRetailers.ValidSubsCount = hndRetailers.get(RetailerID);
					newActiveRetailers.Retailer = EachAcc;
					system.debug('Get EachAcc ' + EachAcc);
					posInList = getPositionInList(EachAcc.BillingPostalCode);
					system.debug('posInList ' + posInList);
					if (posInList >= allActiveRetailers.size())
						allActiveRetailers.add(newActiveRetailers);
					else
						allActiveRetailers.add(posInList,newActiveRetailers);
				}
			}

				system.debug('allActiveRetailers ' + allActiveRetailers);
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'An error occurred. No retailers exist.'));
			system.debug(e);
		}
	}


	public integer getPositionInList(String postcode){
		integer pos=0;
		for (ActiveRetailers eachRetailer: allActiveRetailers){
			if (postcode > eachRetailer.Retailer.BillingPostalCode){
				system.debug('posInList ' + eachRetailer + ' ' + pos);
				pos ++;
			}
		}
		return pos;
	}

	/***************************************************************************************
	Developer - Unknown
	Date - Unknown
	Version - 1.2
	Function - retrieves account record based on RET_ID__c field value without any error returned
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1        	08/2015  	//added check that null/empty is not passed in
	Wiktor Czykin	1.2 		21/10/2015  //added BillingPostalCode - prod quickfix
	****************************************************************************************/
	public static Account returnSelectedRetailerWithoutError(String retailerID) {
		//this confirms that the retailer is a valid retailer and returns the ID
		if(String.isNotBlank(retailerId)){
			List<Account> lstRetailerAccounts = [select Id, Name, BillingPostalCode from Account where RET_ID__c = :retailerID];
			if (!lstRetailerAccounts.isEmpty() && lstRetailerAccounts.size() == 1){
				return lstRetailerAccounts[0];
			}
		}
		return null;
	}

	/***************************************************************************************
	Developer - Unknown
	Date - Unknown
	Version - 1.2
	Function - retrieves account record based on RET_ID__c field value
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1        	08/2015  	//removed try-catch, added check that null/empty is not passed in
	Wiktor Czykin	1.2 		21/10/2015  //added BillingPostalCode just in case
	****************************************************************************************/
	public static Account getRetailerFromRETID(String selectedRetID){
		if(!String.isBlank(selectedRetID)){
			List<Account> lstSelectedRetailerAccount = [select Id, Name, BillingPostalCode from Account where RET_ID__c =:selectedRetID];
			if(!lstSelectedRetailerAccount.isEmpty()){
				return lstSelectedRetailerAccount[0];
			}
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'The selected retailer does not exist, please contact your administrator.'));
		return null;
	}

	/***************************************************************************************
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - retrieves account record based on account Id
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1        	08/2015  	//removed try-catch, added check that null/empty is not passed in
	****************************************************************************************/
	public static Account getRetailerAcc(String selectedRetailer){
		if(!String.isBlank(selectedRetailer)){
			List<Account> lstSelectedRetailerAcc = [select Id, Name, BillingPostalCode from Account where Id = :selectedRetailer limit 1];
			if(!lstSelectedRetailerAcc.isEmpty()){
				return lstSelectedRetailerAcc[0];
			}
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'The selected retailer does not exist, please contact your administrator.'));
		return null;
	}


	public static String convertToTwoDecimalPlaces(Decimal Value) {
		return convertToTwoDecimalPlaces(Value.doubleValue());
	}

	public static String convertToTwoDecimalPlaces(Double value) {
		if(value == null)return '0.00';

		String StoreVal;
		StoreVal = value.format();

		Decimal thisWeeklyPrice = Decimal.valueOf(value);
		if (value.round() != thisWeeklyPrice) //this means that the value must not end in .0
		{
			if (thisWeeklyPrice.scale() == 1)
				StoreVal = StoreVal + '0';

			if (thisWeeklyPrice.scale() > 2){
				thisWeeklyPrice = thisWeeklyPrice.setScale(2);
				StoreVal = ThisWeeklyPrice.format();
			}
		}

		if (StoreVal.contains('.') == false)//If it is a round number with no decimal places
			StoreVal = StoreVal + '.00';

		return StoreVal;
	}

	public static String formatPostCode(String Postcode){
		String ReplaceSpeaceInMailingPostalCode = Postcode.replaceall(' ','');
		String NewPostCode;

		try{
			String[] ThisPostCode = ReplaceSpeaceInMailingPostalCode.split('[0-9]',0);
			String LastDigit = ThisPostCode[ThisPostCode.size()-1];
			Integer LastOccurence = ReplaceSpeaceInMailingPostalCode.lastIndexOf(LastDigit);
			NewPostCode = ReplaceSpeaceInMailingPostalCode.substring(0,LastOccurence - 1) + ' ' + ReplaceSpeaceInMailingPostalCode.substring(LastOccurence-1,ReplaceSpeaceInMailingPostalCode.length() );
			NewPostCode = NewPostCode.toUpperCase();
		}catch (Exception err){
		  return '';
		}

		return NewPostCode;
	}

	public static List<Messaging.Emailfileattachment> createEmailAttachment(String attachBody, String fileName){
	//SMS-462 //SMS-468
		List<Messaging.Emailfileattachment> fileAttachments;
		try{
			Blob fileBody = Blob.valueOf(attachBody);
			fileAttachments = new List<Messaging.Emailfileattachment>();
			Messaging.Emailfileattachment fileAttachment = new Messaging.Emailfileattachment();
			fileAttachment.setBody(fileBody);
			//fileAttachment.setContentType('text/csv');
			fileAttachment.setFileName(fileName);
			fileAttachments.add(fileAttachment);
		}
		catch (Exception err){
		  return null;
		}
		return fileAttachments;
	}

	public static String formatCollectionDate(String ThisDay){
		//This is currently used in DSOS in UtilitiesOnlineSubscription
		if (ThisDay == '1')
			ThisDay = '1st';
		else if (ThisDay == '15')
			ThisDay = '15th';
		return ThisDay;
	}

	public static String reConditionString(String SuppliedString){
		String TempString;
		if (SuppliedString == null)
			return '';
		else
		{
			TempString = SuppliedString.replaceAll('[., \r\n]','');
			TempString = TempString.toUpperCase();

			return TempString;
		}
	}

	public static String convertBooleanToString(Boolean CurrentValue){
		if (CurrentValue)
			return 'Yes';
		else
			return 'No';
	}

	public static Boolean qualifyAgency(String agencyidentifier){
		//checks if agency qualifies and caller is set to true
		Boolean qualify=false;

		List<SubManagementDefaults__c> allAgencies = [Select DefaultValue__c From SubManagementDefaults__c Where ID__c='Agencies'];

		if (allAgencies.size() > 0){
			system.debug('agency '  + allAgencies);
			SubManagementDefaults__c thisSubManagementDefault = allAgencies[0];
			String thisdefault = thisSubManagementDefault.DefaultValue__c;
			qualify = thisdefault.contains(agencyidentifier);
		}

		return qualify;
	}

	public static String getSecureValue(String Value){
		String NewPass;
		try{
			Blob HashPrice = Blob.valueOf(Value);
			String HashPriceStr = HashPrice.toString();
			Blob NewHashPrice= EncodingUtil.base64Decode(HashPriceStr);
			NewPass = NewHashPrice.toString();
		}catch (Exception e){
			system.debug('GetSecureValue: '+e);
			NewPass='';
		}
		return NewPass;
	}

	public static String createSecureValue(String Value){
		String NewHashPrice;
		try{
			Blob HashPrice = Blob.valueOf(Value);
			NewHashPrice= EncodingUtil.base64Encode(HashPrice);
		}
		catch (Exception e){
		   system.debug('CreateSecureValue: '+e);
		   NewHashPrice='';
		}
		return NewHashPrice;
	}

	public static String checkStringIfNull(String TestString){
		if(TestString != null)
			return TestString;
		else
			return '';
	}

	/**
	* @author unknown
	* @date unknown
	* @description Copy the data held in the POC to an account
	*#############Change Log#############
	*Modified by     Version     Change Date
	*Gavin Palmer	 1.1 		 17/06/2016 //added a condition to check against possible duplicate accounts and condition to check email
	*Wiktor Czykin   1.2         19/07/2016 //populating Subscriber_Number_static__c so that can be used on the caller side
	*Wiktor Czykin   1.3	     04/11/2016 //added setting of email 
	**/
	public static Account copyPOCToAccount(POC__c poc){
		List<Account> lstAccount = null;
		String tsNumber = poc.Subscriber_Number__c;
		try{
			if(TMGUtil.isDataValid(tsNumber)){
				lstAccount = [SELECT Id, Subscriber_Number__c, PersonEmail FROM Account WHERE Subscriber_Number_static__c = :tsNumber LIMIT 1];
			} else if(TMGUtil.isDataValid(poc.Email__c)){
				lstAccount = [SELECT Id, Subscriber_Number__c, PersonEmail FROM Account WHERE PersonEmail = :poc.Email__c LIMIT 1];
			} else {
				lstAccount = [SELECT Id, Subscriber_Number__c, PersonEmail FROM Account WHERE POC__c = :poc.POC_ID__c LIMIT 1];
			}
		}catch(System.Exception e){
			System.debug('### No Account found from subscriber number supplied: ' + poc.Subscriber_Number__c);
		}
		Account acc = new Account(	Id = (lstAccount.isEmpty()?null:lstAccount[0].Id),
									POC__c = poc.POC_ID__c,
									PersonMailingStreet = poc.Street__c,
									FirstName = poc.FirstName__c,
									LastName = poc.LastName__c,
									PersonMailingPostalCode = poc.PostalCode__c
		);
		if (poc.Title__c != null) acc.Salutation = poc.Title__c; else acc.Salutation = '';
		if (poc.HomeTelePhone__c != null) acc.PersonHomePhone = poc.HomeTelePhone__c; else acc.PersonHomePhone = '';
		if (poc.MobileTelePhone__c != null) acc.PersonMobilePhone = poc.MobileTelePhone__c; else acc.PersonMobilePhone = '';
		if (poc.City__c != null) acc.PersonMailingCity = poc.City__c; else acc.PersonMailingCity = '';
		if (poc.State__c != null) acc.PersonMailingState = poc.State__c; else acc.PersonMailingState = '';
		if (!lstAccount.isEmpty()){
			if(String.isNotBlank(lstAccount[0].Subscriber_Number__c)){ 
				acc.Subscriber_Number_static__c = lstAccount[0].Subscriber_Number__c;
			}
			if(String.isNotBlank(lstAccount[0].PersonEmail)){
				acc.PersonEmail = lstAccount[0].PersonEmail;
			}
		}
		return acc;
	}

	public static Account copyLapsedAccountToNewAccount(String tsNumber){
		Account acc;
		try{
			acc = [SELECT Salutation, FirstName, LastName, PersonMailingStreet, PersonMailingCity, PersonMailingCountry, PersonMailingState, PersonMailingPostalCode, PersonEmail, PersonHomePhone, PersonMobilePhone, DateofBirth__c, Do_Not_Contact__pc FROM Account WHERE Subscriber_Number_static__c=: tsNumber AND Subscription_Status__c=: 'InActive'];
		}catch (Exception e){
		   system.debug('copyLapsedAccountToNewAccount: '+e);
		   return null;
		}
		return acc;
	}

	public String customerHasNoEmail(Boolean SetEmailDef){
		String ReturnEmail;
		try{
			SetEmail = SetEmailDef;
			system.debug('Setemail' + Setemail);
			if (!SetEmail)//agent wants to enter customers email address
				ReturnEmail = '';
			else{
				if (ReturnEmail == null)
					ReturnEmail = [Select DefaultValue__c From SubManagementDefaults__c Where ID__c='DefaultAgencyEmail'].DefaultValue__c;
			}
			SetEmail = !SetEmail;
			system.debug('ReturnEmail ' + ReturnEmail );
		}
		catch (Exception e){ system.debug(e); }

		return ReturnEmail;
	}

	public static String generateUniqueFileName(String prefixFile, String fileType){
		DateTime dt = System.now();
		Integer y = dt.year();
		Integer m = dt.month();
		Integer d = dt.day();
		String fileName = prefixFile+d+'-'+m+'-'+y;
		Integer randomHash = (Integer) ((d+m+y)<<Crypto.getRandomInteger());
		fileName = fileName+ '_'+ randomHash + '.' + fileType;

		return fileName;
	}
}
