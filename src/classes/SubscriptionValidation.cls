public class SubscriptionValidation {

public String SortCode{get;set;}
public Integer DirectDebitDay{get;Set;}
public String DirectDebitFreq{get;Set;}
public String ValidateAccountError{get;Set;}
public String ValidateDDError{get;Set;}
public String ConfirmEmailAddress{get;Set;}

public Boolean ValidateAccount(Account TestingAccount){
	//test first and last name, post code, email, country if weekly
	Boolean ThisValidateAccount;
	ThisValidateAccount = true;
	ValidateAccountError = '';
	Boolean PhoneEntered = true;

system.debug('TestingAccount ' + TestingAccount);		
	
	system.debug('TestingAccount.FirstName ' + TestingAccount.FirstName);
	if (TestingAccount.FirstName == '' || TestingAccount.FirstName == null)
	{
		ThisValidateAccount =false;
		ValidateAccountError = 'First name';
	}
	
system.debug('ThisValidateAccount ' + ThisValidateAccount);		
	if (TestingAccount.LastName == '' || TestingAccount.LastName == null)
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', Last name';
	}
	
system.debug('ThisValidateAccount ' + ThisValidateAccount);		
system.debug('TestingAccount.PersonMailingPostalCode ' + TestingAccount.PersonMailingPostalCode);		
	
	if (TestingAccount.PersonMailingPostalCode == '' || TestingAccount.PersonMailingPostalCode == null)
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', Post code';
	}

system.debug('ThisValidateAccount ' + ThisValidateAccount);		
	
	system.debug('PersonMailingStreet ' + TestingAccount.PersonMailingStreet );
	if (TestingAccount.PersonMailingStreet == '' || TestingAccount.PersonMailingStreet == null)
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', Street address';
	}

system.debug('ThisValidateAccount ' + ThisValidateAccount);		
		
	if (TestingAccount.PersonMailingCity == '' || TestingAccount.PersonMailingCity == null)
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', City address';
	}

system.debug('ThisValidateAccount ' + ThisValidateAccount);		
system.debug('TestingAccount.PersonEmail ' + TestingAccount.PersonEmail);		

	if ( ConfirmEmailAddress != TestingAccount.PersonEmail)
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', email address and ensure both email addresses match';
system.debug('TestingAccount.PersonEmail ' + TestingAccount.PersonEmail);		
		
	}
	
system.debug('ThisValidateAccount ' + ThisValidateAccount + ' ' + TestingAccount.PersonMobilePhone + ' ' + TestingAccount.PersonHomePhone);	
	try{
	if ((TestingAccount.PersonHomePhone == '' || TestingAccount.PersonHomePhone == null) && (TestingAccount.PersonMobilePhone == '' || TestingAccount.PersonMobilePhone == null) )
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', Home phone and/or Mobile phone';
		PhoneEntered = false;
	}
	
system.debug('ThisValidateAccount ' + ThisValidateAccount + ' ' + TestingAccount.PersonHomePhone);
	if (TestingAccount.PersonHomePhone != null && PhoneEntered == true)
	{
		system.debug('PersonHomePhone ' + TestingAccount.PersonHomePhone.substring(0,1));
		if (TestingAccount.PersonHomePhone.substring(0,1) != '0')
		{
			ThisValidateAccount =false;
			ValidateAccountError = ValidateAccountError + ', Home phone';
		}
	}
		}
	catch (Exception e)
	{
	}
	
	
	try {
	if (TestingAccount.PersonMobilePhone != null && PhoneEntered == true)
	{
		if (TestingAccount.PersonMobilePhone.substring(0,1) != '0')
		{
			ThisValidateAccount =false;
			ValidateAccountError = ValidateAccountError + ', Mobile phone';
		}
	}
		}
	catch (Exception e)
	{
	}
	
system.debug('ThisValidateAccount ' + ThisValidateAccount);		
		
	if (TestingAccount.PersonEmail == '' || TestingAccount.PersonEmail == null)
	{
		ThisValidateAccount =false;
		ValidateAccountError = ValidateAccountError + ', Email address';
	}
system.debug('ThisValidateAccount ' + ThisValidateAccount);	

	if (ValidateAccountError.length() > 0 && ValidateAccountError.substring(0,1) == ',')
		ValidateAccountError = ValidateAccountError.substring(1); //removes the first ,
			
	return ThisValidateAccount;
}

}