/**
* Author:       Sally ElGhoul (Tquila)
* Date:         28/09/2015
* Description:  extension for the page Zuora_SubscriptionAllAmendments
*
* ******************* Change Log *******************
* Sally  ElGhoul	29/2/2016	get the Mid_term_Discount_Reason__c of the amendment
**/
public class Zuora_SubscriptionAllAmendmentsCtrl {
	
	//the list of zuora amendments wrapper to show to user in th
	public List <AmendmentWrapper> lstZuoraAmendments{get;set;}
	
	//the current subscription object
	private final Zuora__Subscription__c zuoraSubscriptionObj;
	
	//the zuora api variable
	private Zuora.zApi api = new Zuora.zApi();
	
	//constructor
	public Zuora_SubscriptionAllAmendmentsCtrl(ApexPages.StandardController stdController){
		
		//get the subscription record
		zuoraSubscriptionObj = (Zuora__Subscription__c)stdController.getRecord();
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        28/09/2015
    Function    This function called in the onload of the page to get all zuora amendments
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
	public void fetchAllAmendments(){
		
		//Get all amendments from Zuora
		lstZuoraAmendments=new List <AmendmentWrapper>();
				
		try{
				if(string.isempty(zuoraSubscriptionObj.Original_Zuora_Subscription_ID__c)){
					throw new TMGUtil.GenericException('Original Zuora Subsciption Id is empty');	
				}
				
				//if not test running
				if ( !Test.isRunningTest() ){
					//login to the api using the user configured in "Zuora API Login Setup" 
					api.zlogin();
				
					//Get all zuora amendments
					list<Zuora.zObject> lstZuoraObjects=Zuora_Utility.getZuoraSubscriptionAmendments(api,zuoraSubscriptionObj.Original_Zuora_Subscription_ID__c);
					
					//Loop on the zuora amendments, filter them and convert them to the wrapper class
					for(Zuora.zObject zuoraObj: lstZuoraObjects){
						
						//exlude the "OwnerTransfer" and "TermsAndConditions" from the returned amendments
						if(zuoraObj.getValue(Constants.ZUORA_AMENDMENT_TYPE_FIELD_NAME)!=Constants.ZUORA_AMENDMENT_TYPE_OWNER_TRANSFER_VALUE && zuoraObj.getValue(constants.ZUORA_AMENDMENT_TYPE_FIELD_NAME)!=constants.ZUORA_AMENDMENT_TYPE_TERMS_AND_CONDITIONS_VALUE){
							lstZuoraAmendments.add(new AmendmentWrapper(zuoraObj));
						}	
					}
				} else //test running
				{
			        AmendmentWrapper wrapperObj1=new AmendmentWrapper();
			        wrapperObj1.EffectiveDate=date.today();
			        wrapperObj1.Description='test Description';
			        wrapperObj1.ZuoraId='Z12344';
			        wrapperObj1.AmendmentName='test Name1';
			        wrapperObj1.Type='test Type';
			        wrapperObj1.Status='test Status1';
			        lstZuoraAmendments.add(wrapperObj1);
			        
			        AmendmentWrapper wrapperObj2=new AmendmentWrapper();
			        wrapperObj2.EffectiveDate=date.today().addDays(3);
			        wrapperObj2.Description='test Description3';
			        wrapperObj2.ZuoraId='Z12344';
			        wrapperObj2.AmendmentName='test Name13';
			        wrapperObj2.Type='test Type3';
			        wrapperObj2.Status='test Status3';
			        lstZuoraAmendments.add(wrapperObj2);
				}
				
				//sort the amendment by the effective date asc
				if(lstZuoraAmendments!=null && lstZuoraAmendments.size()>0){
					lstZuoraAmendments.sort();
				}
		}catch(TMGUtil.GenericException genericExceptionObj){ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getmessage()); ApexPages.addMessage(myMsg);
		}catch(exception ex){system.debug('Error occured to fecth zuora amendment: '+ex);ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'An error Occurred, please contact your system administrator'); ApexPages.addMessage(myMsg);}
	}
	
	
	/**
	* Author:       Sally ElGhoul (Tquila)
	* Date:         29/09/2015
	* Description:  Amendment wrapper class to render Zuora Amendments and sort them
	*
	* ******************* Change Log *******************
	* Sally ElGhoul 	29/2/2016	get the Mid_term_Discount_Reason__c of the zuora amendment 
	**/
	public class AmendmentWrapper implements Comparable{
		public date   EffectiveDate	{get;set;}
		public string Description	{get;set;}
		public string ZuoraId		{get;set;}
		public string AmendmentName	{get;set;}
		public string Type			{get;set;}
		public string Status		{get;set;}
		public String midTermDiscountReason	{get;set;}
		
		//constructor	
		public AmendmentWrapper(Zuora.zObject amendmentZuoraObj){
			EffectiveDate	= date.valueof(amendmentZuoraObj.getvalue(constants.ZUORA_AMENDMENT_EFFECTIVE_DATE_FIELD_NAME));
			Description		= string.valueof(amendmentZuoraObj.getvalue(constants.ZUORA_AMENDMENT_DESCRIPTION_FIELD_NAME));
			ZuoraId			= string.valueof(amendmentZuoraObj.getValue(constants.ZUORA_AMENDMENT_ID_FIELD_NAME));
			AmendmentName	= string.valueof(amendmentZuoraObj.getValue(constants.ZUORA_AMENDMENT_NAME_FIELD_NAME));
			Type			= string.valueof(amendmentZuoraObj.getValue(constants.ZUORA_AMENDMENT_TYPE_FIELD_NAME));
			Status			= string.valueof(amendmentZuoraObj.getValue(constants.ZUORA_AMENDMENT_STATUS_FIELD_NAME));
			
			if(amendmentZuoraObj.getValue(Constants.ZUORA_AMENDMENT_MID_TERM_DISCOUNT_REASON_FIELD_NAME)!=null){
				midTermDiscountReason=string.valueof(amendmentZuoraObj.getValue(Constants.ZUORA_AMENDMENT_MID_TERM_DISCOUNT_REASON_FIELD_NAME));
			}
		}
		
		//empty constructor
		public AmendmentWrapper(){}		
		
		// Implement the compareTo() method to sort the amendments using the effective date
	    public integer compareTo(Object compareTo) {
	        AmendmentWrapper compareToAmendment = (AmendmentWrapper)compareTo;
	        if (EffectiveDate == compareToAmendment.EffectiveDate) return 0;
	        if (EffectiveDate > compareToAmendment.EffectiveDate) return 1;
	        return -1;        
	    }
	}
}