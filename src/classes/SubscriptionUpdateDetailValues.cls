public class SubscriptionUpdateDetailValues {

    public static Double Name_Change_Count{get;set;}
	public static String PersonTitle{get;set;}
	public static String FirstName{get;set;}
	public static String LastName{get;set;}
	public static String PersonMailingPostalCode{get;set;}
	public static String PersonMailingStreet{get;set;}
	public static String PersonMailingCity{get;set;}
	public static String PersonMailingState{get;set;}
	public static String PersonEmail{get;set;}
	public static String ConfirmEmailAddress{get;set;}
	public static String PersonHomePhone{get;set;}
	public static String PersonMobilePhone{get;set;}

public void SetValues(Account ThisAcc){
	Name_Change_Count = ThisAcc.Name_Change_Count__c;
	PersonTitle = ThisAcc.Salutation;
	FirstName = ThisAcc.FirstName;
	LastName  = ThisAcc.LastName;
	PersonMailingPostalCode = ThisAcc.PersonMailingPostalCode;
	PersonMailingStreet = ThisAcc.PersonMailingStreet;
	PersonMailingCity = ThisAcc.PersonMailingCity;
	PersonMailingState = ThisAcc.PersonMailingState;
	PersonEmail = ThisAcc.PersonEmail;
	PersonHomePhone = ThisAcc.PersonHomePhone;
	PersonMobilePhone = ThisAcc.PersonMobilePhone;
	         
}	

}