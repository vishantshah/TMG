public class UtilitiesOnlineSubscriptions {

public list<object> GenericSobj{get;set;}
public String StreetAddressForConfirmDetails{get;set;}
public Boolean SameAddress{get;set;}
public String WeeklyHouseNumber{get;set;}
public String ConfirmEmailAddress{get;set;}
public Boolean ScreenSource{get;set;}

public enum PageName{OpenOffer,Weekly,POC,UpdateDetails}
public enum PayType{DirectDebit,CreditCard}
public enum CurrentPageSection{ThankYouPage,Registration,Delivery,Payment}
public enum EmailType{DefaultType,ForgotPassword}


public Boolean CheckDuplicateAddvress(String ObjName,String sql, String HouseNameFlat, String HouseNumber, Account ReceivedAccObj){
	SameAddress = false;
		 
	list<String> AddressesOfPreviousSubscriptions =  new list<String>();
	String NewEnteredAddress ;
	
	Long testHouseNameFlat;
	Boolean FlatOrHouseName = false;
	Boolean AccHouseNameFlatEntered = false;
	Integer DuplicateOption;
		system.debug('del  ' + HouseNumber + ' del ' + HouseNameFlat);
	String TrimHouseNum;
	
	try{
		TrimHouseNum = HouseNumber.trim();
	}
	catch (Exception e){
			system.debug(e);
			TrimHouseNum = '';
	}				
	
	if (HouseNameFlat != ''){
		system.debug('del 1 ' + HouseNameFlat);
		AccHouseNameFlatEntered = true;
		try{
			testHouseNameFlat = Integer.valueOf(HouseNameFlat); 
			FlatOrHouseName = true;		//is a flat
			StreetAddressForConfirmDetails = 'Flat ' + HouseNameFlat + ' ';
			system.debug('del 2');
		}
		catch (Exception e){
			system.debug('del 3');
		      FlatOrHouseName = false; //house name
		}
	}
	system.debug('check 2 ' + ' TrimHouseNum ' + TrimHouseNum + ' FlatOrHouseName ' + FlatOrHouseName);
		
	if (!(TrimHouseNum == '' || TrimHouseNum == null) && AccHouseNameFlatEntered == true)//object enforces that it is a number
	{
		system.debug('del 4 ' + HouseNumber);
		if (FlatOrHouseName == true){	//search for flat and house number opt 1
			DuplicateOption = 1;
			system.debug('del 5');
		}
		else //house name and house no. entered could be house 30 Flat 3A so allowed
			DuplicateOption = 5;

			NewEnteredAddress = HouseNameFlat + HouseNumber + ReceivedAccObj.PersonMailingCountry + ReceivedAccObj.PersonMailingPostalCode;
			StreetAddressForConfirmDetails = StreetAddressForConfirmDetails + ', ' + HouseNumber;
	}    
	else if ((HouseNumber == ''  || HouseNumber == null) && AccHouseNameFlatEntered == true && FlatOrHouseName == true)//object enforces that it is a number
	{//This is a flat so needs a house no., which hasn't been entered and house name which is a number for a flat
		system.debug('del 6');
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter your flat number and your house number.'));
			return false;
	}
	system.debug('next');
	
	if (FlatOrHouseName == false && AccHouseNameFlatEntered == true && (HouseNumber == ''  || HouseNumber == null) ){
		//house name entered and isn't a no. so isnt a flat and nothing in house number opt 3
		DuplicateOption = 3;
		NewEnteredAddress = HouseNameFlat + ReceivedAccObj.PersonMailingCountry + ReceivedAccObj.PersonMailingPostalCode;
		StreetAddressForConfirmDetails = HouseNameFlat;
		system.debug('del 7');
	}
	system.debug('check 3');
	if (AccHouseNameFlatEntered == false && !(HouseNumber == ''  || HouseNumber == null)  ){
		//house number entered and nothing in house name opt 4
		DuplicateOption = 4;
		NewEnteredAddress = TrimHouseNum + ReceivedAccObj.PersonMailingCountry + ReceivedAccObj.PersonMailingPostalCode;
		StreetAddressForConfirmDetails = TrimHouseNum;
		system.debug('del 7');
	}
	
	if (AccHouseNameFlatEntered == false && (HouseNumber == ''  || HouseNumber == null)  ){
		//nothing entered in either
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'This is invalid. A house name/flat and/or a house number must be entered. Please try again.'));
		return false;	
	}	
	
	system.debug('del 8 ' + AccHouseNameFlatEntered );
	NewEnteredAddress = NewEnteredAddress.replaceall(' ','');
		system.debug('NewEnteredAddress ' + NewEnteredAddress);
	integer iterate = 0;
	String TempAddress;		
	
		
	return true;		
}

public String ToString(Double Value) { 

   String StoreVal;
   StoreVal = Value.format(); 
    
    Decimal ThisWeeklyPrice = decimal.valueOf(Value);
    system.debug('Value ' + Value + ' ' + ThisWeeklyPrice);
    if (Value.round() != ThisWeeklyPrice) //this means that the value must not end in .0
    {
        if (ThisWeeklyPrice.scale() == 1)
        StoreVal = StoreVal + '0';
        
        if (ThisWeeklyPrice.scale() > 2)
        {
            ThisWeeklyPrice = ThisWeeklyPrice.setScale(2);
            StoreVal = ThisWeeklyPrice.format(); 
        }
    }
    system.debug('StoreVal ' +StoreVal); 
    
    If (StoreVal.contains('.') == false)//If it is a round number with no decimal places
        StoreVal = StoreVal + '.00';
        
    return StoreVal;
} 
public String FormatDate(String ThisDay){

if (ThisDay == '1')
    ThisDay = '1st';
else if (ThisDay == '15')
    ThisDay = '15th';
    
    return ThisDay;
}

public String ReConditionString(String SuppliedString){
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

public String ConvertPromoCodesForMyriad(Boolean CurrentValue){
	if (CurrentValue)
		return 'Yes';
	else
		return 'No';
}


public Boolean CheckValidPersonalDetails(Account ThisAccount){
    Boolean ValidDetails;
    system.debug(ThisAccount);
    String PhoneErrorMsg;
    try{
        if (ThisAccount.PersonMobilePhone.substring(0,1) != '0')
        {
            PhoneErrorMsg = 'Please enter a zero at the start of your mobile number.';
    
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, PhoneErrorMsg));
        }
        else
            ValidDetails = true;  
    }
    catch (Exception e){
        system.debug('Confirm Details err ' + e);
    }
    
    try{
        if (ThisAccount.PersonHomePhone.substring(0,1) != '0')
        {
            PhoneErrorMsg = 'Please enter a zero at the start of your phone number.';
    
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, PhoneErrorMsg));
        } 
        else
            ValidDetails = true;
            
            system.debug('P '  +  PhoneErrorMsg);
        }
        catch (Exception e){
            system.debug('Confirm Details err ' + e);
    }
    
    return ValidDetails;
} 

public Boolean SaveUpdateDetailsTaskHistory(){

	return true;
}

public Pagereference SetSubscriptionDetails(){
    Pagereference pr = null; 
    return pr;
}

public Boolean QualifyAgency(String agencyidentifier){
//checks if agency qualifies and caller is set to true
Boolean qualify=false;

String ThisAgency = String.valueOf([Select DefaultValue__c From SubManagementDefaults__c Where ID__c='Agencies'].DefaultValue__c);

system.debug('agency '  + ThisAgency);
	qualify = ThisAgency.contains(agencyidentifier);

return qualify;
}

public void InsertSubscriptionIncentive(String SelectedIncentive, Id SubID){
//create new SubscriptionIncentiveAssociation__c record linked to new Sub SMS-310 
try{
	Id IncentiveId = [Select id From Incentive__c Where Incentive_Description__c=:SelectedIncentive limit 1].id;
	SubscriptionIncentiveAssociation__c	ThisIncentive =  new SubscriptionIncentiveAssociation__c(Date_Requested__c=System.Today(),Incentive__c=IncentiveId, Reason__c='Acquisition Incentive', Subscription__c=SubID);
	system.debug('ThisIncentive ' + ThisIncentive);
	insert ThisIncentive;
}
catch (Exception e){
	system.debug(e);
	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Your subscription has successful been created. However an error occurred saving your choosen incentive. Please telephone our contact centre on 0800 33 20 20, lines are open from 9am to 5pm Monday to Friday and 9am to 1pm Saturday. '));		
}	
	
}

}