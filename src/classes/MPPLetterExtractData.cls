/**
* @author Unknown
* @date Unknown
* @description Helper class for MPP Letter Extract
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         22/10/2015  //modified createCSV_Row() for Subscription, added new fields to non-digital queries generating methods
Wiktor Czykin	1.2			18/11/2015	//modified BatchLogger wrapper variables visibility
Wiktor Czykin	1.3			21/01/2016	//modified createCSV_Row()
Lynette Lim	    1.4			22/01/2016	//modified createCSV_Row() to consider the date format before parsing
Lynette Lim	    1.5			26/01/2016	//modified createCSV_Row() to change payment-collection-date
Wiktor Czykin	1.6			08/02/2016	//modified createCSV_Row() version for Print - made sure that more of SFDC data is used rather than from MPP callout response (as invalid).
										//created common set of fields to fetch.
Wiktor Czykin	1.7			17/02/2016	//modified getTitle()
**/
public with sharing class MPPLetterExtractData {
	
	/**
	* @author Unknown
	* @date Unknown
	* @description Helper class for file handling in extract batch job
	#############Change Log#############
	Modified by     Version     Change Date
	**/
	public virtual class BatchLogger{
		@TestVisible protected String csvHeader;
		@TestVisible protected String csvData;
		@TestVisible protected String log;
		@TestVisible public String logHeader;
		@TestVisible private String fileName;
			
		public BatchLogger(String fileName, String csvHeader){
			this.fileName = fileName;
			this.csvheader = csvHeader;	
			this.csvData = '';
			this.log = this.logHeader = '';
			setLogHeader('----------------------- Log Messages for ' + this.fileName + ' -----------------------\n\n');
		}
		
		public void setLogHeader(String header){
			this.logHeader = header;
		}
		
		public void addLog(String msg){
			this.log += msg + '\n';
		}
		
		public String getLog(){
			return this.logHeader + this.log;
		}
		
		public Boolean isCSVDataValid(){
			return (this.csvData != null && this.csvData.length() > 0);
		}
		
		public void addCSVData(String row){
			this.csvData += row + '\n';
		}
		
		public String getFileName(){
			return this.fileName;
		}
		
		public String getCSVHeader(){
			return this.csvHeader;
		}
		
		public String getCSVData() {
			return this.csvHeader + this.csvData;
		}
	}
	
	public class DigitalSubscriber{
		public Account acc;
		public DateTime subStartDate;
	}
	
	public class SubscriberTransaction{
		public Account acc;
		public List<MPP_Transaction_History__c> monthly = new List<MPP_Transaction_History__c>();
		public List<MPP_Transaction_History__c> annual = new List<MPP_Transaction_History__c>();
		
		public SubscriberTransaction(){}
		public SubscriberTransaction(Account acc){
			this.acc = acc;
		}
	}
	//header fields for csv
	public static final String CSV_DDCCA_HEADER = 'TS Number, Subscription Start Date, DD AUDDIS Ref, Title, First Name, Last Name, Address Line 1, Address Line 2, Address Line 3, '
		+ 'Person Mailing City, Person Mailing State, Person Mailing Postal Code, Sort Code, Account Number, First Collection Date, Collection Frequency, Collection Date, '
		+ 'First Collection Amount, Ongoing Collection Amount, Credit Card Number, Credit Card Expiry Date, Credit Card Auth Code, Subsequent Amount, Subsequent Payment Date ' + '\n';
	

	private static final Set<String> SET_FIELDS_TO_FETCH = new Set<String>{	'Id',
																			'Name',
																			'Subscriber__r.Id',
																			'Subscriber__r.Subscriber_Number_static__c',
																			'Subscriber__r.FirstName', 
																			'Subscriber__r.LastName',
																			'Subscriber__r.PersonTitle',
																			'Subscriber__r.Salutation',
																			'Subscriber__r.Title__c',
																			'Subscriber__r.PersonMailingStreet', 
																			'Subscriber__r.PersonMailingCity',
																			'Subscriber__r.PersonMailingState', 
																			'MPP_Premium_Subscription_ID__c',
																			'Subscriber__r.PersonMailingPostalCode', 
																			'Subscriber__r.IsUsingMPP__c',
																			'Start_Date__c',
																			'Subscription_Status__c', 
																			'Is_MPP_DDCCA_Letter_Extracted__c', 
																			'Last_Status_Change__c',
																			'LastModifiedDate',
																			'MPP_Subsequent_Amount__c',
																			'MPP_Subsequent_Payment_Date__c',
																			'MPP_DD_Frequency__c',
																			'MPP_CC_Frequency__c',
																			'RecordTypeId',
																			'MPP_DD_Next_Payment_Date__c',
																			'MPP_CC_Next_Payment_Date__c',	
																			'MPP_CC_First_Payment_Amount__c',
																			'MPP_DD_First_Payment_Amount__c',
																			'PaymentDate__c',
																			'Weekly_Price__c',
																			'Low_Start_Weekly_Price__c',
																			'Subscription_Duration_Picklist__c'
																			
	};

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 08/02/2016
    Version - 1.0
    Function - generates soql fields in string format
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@TestVisible private static String getFieldsToQuery(){
		String sFieldsToQuery = '';
		for(String sField : SET_FIELDS_TO_FETCH){
			sFieldsToQuery += sField +',';
		}
		if(sFieldsToQuery.length()>0){
			sFieldsToQuery = sFieldsToQuery.substring(0, sFieldsToQuery.length()-1);
		}
		return sFieldsToQuery;
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - generates soql string for batch
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/10/2015  //added extra low start related fields 
    Wiktor Czykin	1.2			09/02/2016	//modified how soql fields are identified
    ****************************************************************************************/
	public static String getMPP_DDCCA_BatchQuery(){
		PDD_Settings__c cpd = PDD_Settings__c.getValues('Custom MPP DDCCA Date');	
		Date dateRange = ((cpd != null && cpd.DD_Created_Date__c != null) ? cpd.DD_Created_Date__c : Date.today().addDays(-1));
		String dateCriteria = DateTime.newInstance(dateRange.year(), dateRange.month(), dateRange.day()).format('yyyy-MM-dd');
		String statusChange = (cpd != null && cpd.Ignore_Date__c != true ? 'Last_Status_Change__c = ' + dateCriteria + ' AND Is_MPP_DDCCA_Letter_Extracted__c = false' : 'Is_MPP_DDCCA_Letter_Extracted__c = false');
		
		String query = 'SELECT  ' + getFieldsToQuery() + ' FROM Subscription__c  WHERE ((Subscriber__r.IsUsingMPP__c = true AND Subscription_Status__c = \'Pending\') AND (' + statusChange + ')';
			
		//Create a list of DSOS users.
		Set<Id> dsosUsers = new Set<Id>();
		for(User a :[SELECT Id FROM User Where Name IN('TMG-POCSignup GuestUser', 'TMG-OpenOffer Guest User')]){
			dsosUsers.add(a.Id);
		}
		query += 'AND (CreatedById NOT IN ' + TMGUtil.parenthesizeList(new List<Id>(dsosUsers)); 
		query += + ' AND MPP_Premium_Subscription_ID__c != NULL))';
		query += 'ORDER BY Subscriber__r.Subscriber_Number_static__c ASC';
		return query;
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - 	generates soql string for batch 
    			// Changed on SOQL query  to calculate list of subscriptions where Payment_Type__c will be Credit Card
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/10/2015  //added extra low start related fields
    Wiktor Czykin	1.2			09/02/2016	//modified how soql fields are identified
    ****************************************************************************************/
	public static String getMPP_CCA_BatchQuery(){
		PDD_Settings__c cpd = PDD_Settings__c.getValues('Custom MPP DDCCA Date');	
		Date dateRange = ((cpd != null && cpd.DD_Created_Date__c != null) ? cpd.DD_Created_Date__c : Date.today().addDays(-1));
		String dateCriteria = DateTime.newInstance(dateRange.year(), dateRange.month(), dateRange.day()).format('yyyy-MM-dd');
		String statusChange = (cpd != null && cpd.Ignore_Date__c != true ? 'Last_Status_Change__c = ' + dateCriteria + ' AND Is_MPP_DDCCA_Letter_Extracted__c = false' : 'Is_MPP_DDCCA_Letter_Extracted__c = false');
		
		String query = 'SELECT ' + getFieldsToQuery() + ' FROM Subscription__c WHERE ((Subscriber__r.IsUsingMPP__c = true AND Subscription_Status__c IN( \'Pending\',\'Offered\')) AND Payment_Type__c = \'Credit Card\' AND ((Is_Renewal__c=\'Renewal\' AND Previous_Subscription__r.isContinuous__c =false) OR (Is_Renewal__c<>\'Renewal\')) AND isContinuous__c =true AND (' + statusChange + ')';
			
		//Create a list of DSOS users.
		Set<Id> dsosUsers = new Set<Id>();
		for(User a :[SELECT Id FROM User Where Name IN('TMG-POCSignup GuestUser', 'TMG-OpenOffer Guest User')]){
			dsosUsers.add(a.Id);
		}
		
		query += 'AND (CreatedById NOT IN ' + TMGUtil.parenthesizeList(new List<Id>(dsosUsers)); 
		query += + ' AND MPP_Premium_Subscription_ID__c != NULL))';
		query += 'ORDER BY Subscriber__r.Subscriber_Number_static__c ASC';
		return query;
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - 	generates soql string for batch 
    			// Changed on SOQL query  to calculate list of subscriptions where Payment_Type__c will be Credit Card
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/10/2015  //added extra low start related fields
    Wiktor Czykin	1.2			09/02/2016	//modified how soql fields are identified
    ****************************************************************************************/
	public static String getMPP_DD_BatchQuery(){
		PDD_Settings__c cpd = PDD_Settings__c.getValues('Custom MPP DDCCA Date');	
		Date dateRange = ((cpd != null && cpd.DD_Created_Date__c != null) ? cpd.DD_Created_Date__c : Date.today().addDays(-1));
		String dateCriteria = DateTime.newInstance(dateRange.year(), dateRange.month(), dateRange.day()).format('yyyy-MM-dd');
		String statusChange = (cpd != null && cpd.Ignore_Date__c != true ? 'Last_Status_Change__c = ' + dateCriteria + ' AND Is_MPP_DDCCA_Letter_Extracted__c = false' : 'Is_MPP_DDCCA_Letter_Extracted__c = false');
		
		String query = 'SELECT ' + getFieldsToQuery() + ' FROM Subscription__c WHERE ((Subscriber__r.IsUsingMPP__c = true AND Subscription_Status__c IN( \'Pending\',\'Offered\')) AND Payment_Type__c = \'Direct Debit\' AND ((Is_Renewal__c=\'Renewal\' AND Previous_Subscription__r.isContinuous__c =false) OR (Is_Renewal__c<>\'Renewal\')) AND isContinuous__c =true AND (' + statusChange + ')';
			
		//Create a list of DSOS users.
		Set<Id> dsosUsers = new Set<Id>();
		for(User a :[SELECT Id FROM User Where Name IN('TMG-POCSignup GuestUser', 'TMG-OpenOffer Guest User')]){
			dsosUsers.add(a.Id);
		}
		
		query += 'AND (CreatedById NOT IN ' + TMGUtil.parenthesizeList(new List<Id>(dsosUsers)); 
		query += + ' AND MPP_Premium_Subscription_ID__c != NULL))';
		query += 'ORDER BY Subscriber__r.Subscriber_Number_static__c ASC';
		return query;
	}
	
	public static final String CSV_DIGITAL_SUBSCRIBER_HEADER = 'TS Number, Subscription Product, Subscription Start Date, Title, First Name, Last Name, Address Line 1, ' 
		+ 'Address Line 2, Address Line 3, Person Mailing City, Person Mailing State, Person Mailing Postal Code\n';
		
	public static String getMPP_Digital_BatchQuery(){
		String query = 'SELECT Id, CreatedDate, Subscriber_Number_static__c, PersonTitle, Salutation, Title__c, FirstName, LastName, PersonMailingStreet, PersonMailingCity, '
			+ 'PersonMailingState, PersonMailingPostalCode, IsUsingMPP__c, Is_Digital_Letter_Extracted__c, Digital_Product_Type__c, Subscriber_Digital_Status__c, ' 
			+ 'PersonMailingCountry, (SELECT Id, CreatedDate, Subscriber__c, Payment_Type__c, Payment_Status__c, Total_Price__c FROM MPP_Transaction_Histories__r ' 
			+ 'WHERE Payment_Type__c = \'CreditDebitCard\' AND Payment_Status__c = \'Success\' AND DD_Transaction_Type__c != \'AUDDIS\' ORDER BY CreatedDate ASC LIMIT 2)'
			+ 'FROM Account WHERE IsUsingMPP__c = true AND Subscriber_Digital_Status__c = \'Active\''
			+ 'AND Is_Digital_Letter_Extracted__c = false AND Digital_Product_Type__c = \'' + Constants.DIGITAL_PRODUCT_ALLDEVICES + '\' '
			+ 'AND PersonMailingCountry = \'GB\'';
		return query;
	}
	
	public static String createFileName(String name, String ext, Integer setting){
		String fileName = name;
		Date dateRange;
		if(setting == 1){
			PDD_Settings__c cpd = PDD_Settings__c.getValues('Custom PDD Date');	
			dateRange = ((cpd != null && cpd.DD_Created_Date__c != null) ? cpd.DD_Created_Date__c : Date.today().addDays(-1));
		}else{
			dateRange = Date.today();
		}
		fileName += dateRange.format().replaceAll('/', '-') + '_' + Math.abs(Integer.valueOf((dateRange.day() + dateRange.month() + dateRange.year()) << Crypto.getRandomInteger()));
		fileName += '.' + ext;
		return fileName;
	}
	
	public static String retrieveFileName(String fileName){
		if(!isValid(fileName)){
			return null;
		}else{
			return fileName.substring(0, fileName.indexOf('.')).trim();
		}
	}
	
	public static Boolean isValid(Object data){
		return !(data == null || String.valueOf(data).length() == 0);
	}
	
	public static String getValidCSV_Value(String data){
		if(!isValid(data)){
			return ' ';
		}else{
			return data;
		}
	}	
	
	public static String pad(String padStr, Integer amount){
		String pad = '';
		for(Integer i = 0; i < amount; i++){
			pad += padStr;	
		}
		return pad;
	}
	
	public static String leftPadding(String str, String padStr, Integer offset){
		if(!isValid(str)){
			return null;
		}else{
			String rStr = str.substring(str.length()-offset, str.length());
			String lStr = pad(padStr, str.length()-rStr.length()) + rStr;
			return lStr;
		}
	}
	
	public static String prefixPadding(String str, String padStr, Integer amount){
		if(!isValid(str)){
			return null;
		}else{
			String result = pad(padStr, amount) + str;
			return result;
		}	
	}
	
	public static String replaceCommaWithSpace(String theData){
		if(!isValid(theData)){
			return null;
		}else{
			return theData.replaceAll(',', ' ');
		}
	}
	
	public static String getDate(String theDate){
		if(!isValid(theDate)){
			return null;
		}else if (theDate.contains('T')){
			String pDate = theDate.substring(0, theDate.indexOf('T'));
			List<String> sDate = pDate.split('-');
			return (sDate[2] + '/' + sDate[1] + '/' + sDate[0]).replaceAll(' ', '');
		} else {
			String pDate = theDate.substring(0, theDate.indexOf(' '));
			List<String> sDate = pDate.split('-');
			return (sDate[2] + '/' + sDate[1] + '/' + sDate[0]).replaceAll(' ', '');
		}	
	}
	
	public static String getSFDCDate(Date theDate){
		if(!isValid(theDate)){
			return null;
		}else{
			return DateTime.newInstance(theDate.year(), theDate.month(), theDate.day()).format('dd/MM/yyyy');
		}
	}
	
	public static String getSFDCDate(DateTime theDate){
		if(!isValid(theDate)){
			return null;
		}else{
			return theDate.format('dd/MM/yyyy');
		}
	}
	
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - method that identifies proper title/salutation for the customer
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         17/02/2016  //changed the priority of the fields used to identify title value
    ****************************************************************************************/
	public static String getTitle(String personTitle, String salutation, String title){
		String pTitle = '';
		
		 if(salutation != null && salutation.length() > 0) {
			pTitle = replaceCommaWithSpace(salutation);
		}else if (title != null && title.length() > 0) {
			pTitle = replaceCommaWithSpace(title);
		}else if(personTitle != null && personTitle.length() > 0) {					
			pTitle = replaceCommaWithSpace(personTitle);
		}else{
			pTitle = '';
		}
		
		return pTitle;
	}
	
	public static String getMailingAddress(String mailingStreet){
		String pAddress = '';
		
		if(mailingStreet != null && mailingStreet.length() > 0){
			//Replace commas by semi-colon
			mailingStreet = replaceCommaWithSpace(mailingStreet);
			//Replace return feed with nothing
			mailingStreet = mailingStreet.replace('\r', '');
			//Assumption made here is that the max number of address lines is 5
			List<String> addressLines = mailingStreet.split('\n');
			
			if(addressLines != null && !addressLines.isEmpty()){
				Integer lineCount = 0;
				
				for(String line: addressLines) {							
					lineCount++;
				}
				
				if(lineCount == 1) {
					//only one address line
					pAddress = getValidCSV_Value(addressLines[0]) + ', ';
					//other 2 lines are empty
					pAddress += getValidCSV_Value(null) + ', ';
					pAddress += getValidCSV_Value(null) + ', ';
				}else if(lineCount == 2) {
					//two address line
					pAddress = getValidCSV_Value(addressLines[0]) + ', ';
					pAddress += getValidCSV_Value(addressLines[1]) + ', ';
					//3 line empty
					pAddress += getValidCSV_Value(null) + ', ';
				}else if(lineCount == 3) {
					//3 address line
					pAddress = getValidCSV_Value(addressLines[0]) + ', ';
					pAddress += getValidCSV_Value(addressLines[1]) + ', ';
					pAddress += getValidCSV_Value(addressLines[2]) + ', ';
				}else if(lineCount == 4) {
					//4 address line
					pAddress = getValidCSV_Value(addressLines[0]) + ';' + getValidCSV_Value(addressLines[1]) + ', ';
					pAddress += getValidCSV_Value(addressLines[2]) + ', ';
					pAddress += getValidCSV_Value(addressLines[3]) + ', ';
				}else {
					//5 address lines
					pAddress = getValidCSV_Value(addressLines[0]) + ';' + getValidCSV_Value(addressLines[1]) + ', ';
					pAddress += getValidCSV_Value(addressLines[2]) + ';' + getValidCSV_Value(addressLines[3]) + ', ';
					pAddress += getValidCSV_Value(addressLines[4]) + ', ';
				}
			}
			
		}else{
			//Skip address columns;
			pAddress = getValidCSV_Value(null) + ', ';
			pAddress += getValidCSV_Value(null) + ', ';
			pAddress += getValidCSV_Value(null) + ', ';
		}
		
		return pAddress;
	}
	
	public static String buildParamMap(List<Subscription__c> subs){
		String params = '';
		Integer i = 0;
		for(Subscription__c sub :subs){
			String step = ((i + 1) < 10 ? '0' + String.valueOf(i + 1) : String.valueOf(i + 1));
			params += 'AccountDetailsParamName' + step/*(i + 1)*/ + '=TSNumber&' + 'AccountDetailsParamValue' + step/*(i + 1)*/ + '=' 
				+ sub.Subscriber__r.Subscriber_Number_static__c + (i == subs.size()-1 ? '' : '&');
			i++;	
		}
		return params;
	}
	
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - csv row generating method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/10/2015  //added irregular frequency mapping and new fields MPP_Subsequent_Amount__c and MPP_Subsequent_Payment_Date__c
    Wiktor Czykin	1.2			22/01/2016	//added hotfix for irregular dates being as-is instead of 1st or 15th
    Wiktor Czykin	1.3			08/02/2016	//modified so that date and currency values are based on salesforce data as MPP sends
    											old details in their getPaymentDetails call for renewals
    ****************************************************************************************/
	public static String createCSV_Row(Subscription__c subscription, MPPInterfaceHTTP.PaymentDetailResult payment){
		String record = '';
		
		/*Salesforce side.*/
		//TS Number.
		record += getValidCSV_Value(subscription.Subscriber__r.Subscriber_Number_static__c) + ', ';
		//Subscription Start Date.
		record += getValidCSV_Value(getSFDCDate(subscription.Start_Date__c)) + ', ';
		/*MPP Side*/
		record += getValidCSV_Value(payment.payerRef) + ', ';
		/*Salesforce side.*/
		//Person Title.
		record += getValidCSV_Value(getTitle(subscription.Subscriber__r.PersonTitle, 
											 subscription.Subscriber__r.Salutation, 
											 subscription.Subscriber__r.Title__c)) + ', ';
		//First Name.
		record += getValidCSV_Value(subscription.Subscriber__r.FirstName) + ', ';
		//Last Name.
		record += getValidCSV_Value(subscription.Subscriber__r.LastName) + ', ';
		//Mailing Street - Address Lines.
		record += getMailingAddress(subscription.Subscriber__r.PersonMailingStreet);
		//Mailing City.
		record += getValidCSV_Value(replaceCommaWithSpace(subscription.Subscriber__r.PersonMailingCity)) + ', ';
		//Mailing State.
		record += getValidCSV_Value(replaceCommaWithSpace(subscription.Subscriber__r.PersonMailingState)) + ', ';
		//Mailing Postal Code.
		record += getValidCSV_Value(replaceCommaWithSpace(subscription.Subscriber__r.PersonMailingPostalCode)) + ', ';
		/*MPP side.*/
		//Sort Code.
		record += getValidCSV_Value(payment.sortCode) + ', ';
		//Account Number.
		record += getValidCSV_Value(payment.accNumber) + ', ';
		
		//First Collection Date.
		String sFirstCollectionDate = '';
		//I think it could be set based on MPP_Scheduled_First_Payment_Date__c
		if(subscription.MPP_CC_Next_Payment_Date__c != null){
			sFirstCollectionDate = subscription.MPP_CC_Next_Payment_Date__c+'';
		}else if(subscription.MPP_DD_Next_Payment_Date__c != null){
			sFirstCollectionDate = subscription.MPP_DD_Next_Payment_Date__c+'';
		}
		record += getValidCSV_Value(getDate(sFirstCollectionDate)) + ', ';

		//Collection Frequency.
		String sFrequency = '';
		if(String.isNotBlank(subscription.MPP_CC_Frequency__c)){
			sFrequency = subscription.MPP_CC_Frequency__c;
		}else if(String.isNotBlank(subscription.MPP_DD_Frequency__c)){
			sFrequency = subscription.MPP_DD_Frequency__c;
		}
		record += getValidCSV_Value(sFrequency) + ', ';

		//Collection day: 1 or 15.
		record += getValidCSV_Value(subscription.PaymentDate__c) + ', ';
		
		//First Collection Amount.
		String sFirstCollectionAmount = '';
		if(subscription.MPP_DD_First_Payment_Amount__c != null){
			sFirstCollectionAmount = subscription.MPP_DD_First_Payment_Amount__c+'';
		}else if(subscription.MPP_CC_First_Payment_Amount__c != null){
			sFirstCollectionAmount = subscription.MPP_CC_First_Payment_Amount__c+'';
		}	
		record += getValidCSV_Value(sFirstCollectionAmount) + ', ';


		//Ongoing Collection Amount.
		String sOngoingCollectionAmount = '';
		if(subscription.RecordTypeId != RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName())){
			try{
				MppUtil.PaymentSetupWrapper psw = MppUtil.generatePaymentSchedule(	subscription.Weekly_Price__c, 
																					Integer.valueOf(subscription.Subscription_Duration_Picklist__c),
																					getDate(subscription.Start_Date__c+''), 
																					sFrequency);
				if(psw.lstPaymentSetup != null && !psw.lstPaymentSetup.isEmpty() && psw.lstPaymentSetup.size() > 1){
					sOngoingCollectionAmount = ((Decimal)((Decimal)psw.lstPaymentSetup[1].GrossAmount / 100))+'';
				}
			}catch(Exception e){
				//fail silently
			}
		}
		record += getValidCSV_Value(sOngoingCollectionAmount) + ', ';

		//Credit Card No.
		record += getValidCSV_Value(prefixPadding(payment.creditCardNumber, '*', 8)) + ', ';
		//Credit Card Expiry Date.
		record += getValidCSV_Value(payment.creditCardExpiryDate) + ', ';
		//Credit Card Auth Code.
		record += getValidCSV_Value(payment.creditCardAuthCode) + ', ';
		//MPP Subsequent AmoungetValidCSV_Valuet
		record += (subscription.MPP_Subsequent_Amount__c!=null?subscription.MPP_Subsequent_Amount__c.setScale(2)+'':' ' ) + ', ';
		//MPP Subsequent Payment Date 
		record += getValidCSV_Value(getSFDCDate(subscription.MPP_Subsequent_Payment_Date__c));
		
		subscription.Is_MPP_DDCCA_Letter_Extracted__c = true;
		return record;
	}
	
	public enum freqType{MONTHLY, ANNUAL, UNKNOWN}
	
	//Hack to find out frequency of the transaction history amount.
	public static String getDigitalFrequency(Decimal amount){
		if(amount <= 30){
			return freqType.MONTHLY.name();
		}else if(amount >= 50){
			return freqType.ANNUAL.name();
		}else{
			return freqType.UNKNOWN.name();
		}
	}
	
	public static String createCSV_Row(DigitalSubscriber subscriber){
		System.debug('#### MAP ROW: ' + subscriber);
		String record = '';
		
		//Ts Number.
		record += getValidCSV_Value(subscriber.acc.Subscriber_Number_static__c) + ', ';
		//Subscription Product.
		record += getValidCSV_Value(subscriber.acc.Digital_Product_Type__c) + ', ';
		//Subscription Start Date.
		record += getValidCSV_Value(getSFDCDate(subscriber.subStartDate)) + ', ';
		//Person Title.
		record += getValidCSV_Value(getTitle(subscriber.acc.PersonTitle, 
											 subscriber.acc.Salutation, 
											 subscriber.acc.Title__c)) + ', ';
		//First Name.
		record += getValidCSV_Value(subscriber.acc.FirstName) + ', ';
		//Last Name.
		record += getValidCSV_Value(subscriber.acc.LastName) + ', ';
		//Mailing Street - Address Lines.
		record += getMailingAddress(subscriber.acc.PersonMailingStreet);
		//Mailing City.
		record += getValidCSV_Value(replaceCommaWithSpace(subscriber.acc.PersonMailingCity)) + ', ';
		//Mailing State.
		record += getValidCSV_Value(replaceCommaWithSpace(subscriber.acc.PersonMailingState)) + ', ';
		//Mailing Postal Code.
		record += getValidCSV_Value(replaceCommaWithSpace(subscriber.acc.PersonMailingPostalCode)) + ', ';
				
		subscriber.acc.Is_Digital_Letter_Extracted__c = true;
		return record;
	}
}