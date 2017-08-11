/**
* @author Unknown
* @date Unknown
* @description Controller for retailer search
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin	1.1			12/01/2016 small clean-up
**/
public class SearchRetailerController {
	
	private UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
	private UtilitySelectOptionsSubscriptions selectOptionUtils = new UtilitySelectOptionsSubscriptions();  
	
    public Account retailerAccount;
    public Boolean displayRetailers{get;set;} 
   	public String postcodeRetailSearch{get;set;}
    public String selectedDelivery{get;set;}
    public String selectedRetailer{get;set;}	
	public List<ActiveRetailers> allActiveRetailers{get;set;}
	public Boolean displayRetailerResults{get;set;}
	public String selectedRetailerName{get;set;}
	public Boolean displaySelectedRetailerMsg{get;set;}
	public Boolean displaySelectColumn{get;set;}
	public String defaultDelivery{get;set;}	
	public Boolean displaySelectDeliveryType{get;set;}
	public String agencyIdentifier{get;Set;}	
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			13/01/2016	//removed setting of default delivery as made no sense in component controller as always null		
    ****************************************************************************************/
	public SearchRetailerController(){
		this.displayRetailerResults = false;
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - generates delivery picklist options
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public List<SelectOption> getDeliveryOptions() {	
		if (this.agencyIdentifier == Constants.AGENT_TMG){
			return UtilitySelectOptionsSubscriptions.getDeliveryOptions(true); 
		}else{   //3rd Party orderMethod = 'OutBound'
			return UtilitySelectOptionsSubscriptions.getDeliveryOptions(false);
		}
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - retrieves selected retailer details or null if not found
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public PageReference saveRetailer(){
	    if (this.retailerAccount == null){
			this.retailerAccount = new Account();
	    }
		this.retailerAccount = UtilitiesForSubscriptions.getRetailerAcc(this.selectedRetailer);
		this.selectedRetailerName = this.retailerAccount.Name;
		this.displaySelectedRetailerMsg = true;
		return null;
	}	

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public PageReference setDelivery(){
		if (this.selectedDelivery == Constants.DELIVERYTYPE_OTC){
			this.displayRetailers = false;
			this.displayRetailerResults = false;
		}else{
			this.displayRetailers = true;
			this.displayRetailerResults = true;
		}
		return null;
	}	
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - retrieves all retailers - no active sub condition
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public PageReference retrieveFullListRetailers(){
		this.lookupRetailers(false);
		return null; 
	}	
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - retrieves retailers that have at least one active subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public PageReference retrieveAllRetailers(){
		this.lookupRetailers(true);
		return null; 
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - retrieves retailers
    #############Change Log#############
    Modified by     Version     Change Date
	Wiktor Czykin	1.1			13/01/2016	//removed exception as already handled in fastretrieveRetailers
    ****************************************************************************************/
	public void lookupRetailers(Boolean activeRetailers){
		this.subutils.fastretrieveRetailers(this.postcodeRetailSearch, activeRetailers);
		this.displayRetailers = this.subUtils.displayRetailers;	
		this.allActiveRetailers = this.subUtils.allActiveRetailers;	
	}
}