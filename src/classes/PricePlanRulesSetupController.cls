/**
* Author:       Sally ElGhoul (Accenture)
* Date:         13/04/2016
* Description:  The controller for the page Price_Plan_Rules_Setup
*
* ******************* Change Log *******************
* Modified by       Change Date
* Gavin Palmer      03/05/2016   Removed refreshUI method from the page as it had no use
* Pawel Chrzanowski 05/07/2016   Added Offers map population in Constructor
**/
public class PricePlanRulesSetupController {
	
	public Boolean displayEditSection {get;set;}
	public Plan__c planObj {get;set;}
	public Id selectedPricePlanRuleId {get;set;}
	public Price_Plan__c pricePlanRuleObj {get;set;}
	public CoreApiResources.CoreApiOffers allOffersObj {get;set;}
	public Price_Plan_Offer__c pricePlanDefaultOffer {get;set;}
	public List<AlternativeOfferClass> lstAlternativeOffers {get;set;}
	public Map<String,String>  mapProductIdProductName{get;set;}
	public Map<String,String> mapOfferCodeOfferName	{get;set;}
	public Map<Id,String> mapProductIdProductRegion {get;set;}
	public Map<String,String> mapProductNameProductRegion {get;set;}
    public Id planId {get;set;}

	/***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         05/07/2016  //Added Offers map population
    ****************************************************************************************/
	public PricePlanRulesSetupController(){
        this.planId = ApexPages.currentPage().getParameters().get(Constants.ID_QUERY_STRING);
        if(this.planId == null) throw new TelegraphApplicationException(Label.Price_Plan_Missing_Id);
        
		displayEditSection = false;
		mapProductIdProductName = new Map<String,String>();
		mapOfferCodeOfferName = new Map<String,String>();
		lstAlternativeOffers = new List<AlternativeOfferClass>();
		mapProductIdProductRegion = new Map<Id,String>();
		mapProductNameProductRegion = new Map<String,String>();
		
		getPlanDetails();
		if(this.planObj == null) throw new TelegraphApplicationException(Label.Price_Plan_Retrieve_Records_Error);
		
        //populate Offers map from CoreAPI
		allOffersObj = CoreAPICalloutUtility.GetAllOfferCodes();
        if(TMGUtil.isDataValid(allOffersObj)){
            for(CoreApiResources.CoreApiOfferDetails offerDetailsObj : allOffersObj.offers){
                if(!mapOfferCodeOfferName.containsKey(offerDetailsObj.tmgId)){
                    mapOfferCodeOfferName.put(offerDetailsObj.tmgId, offerDetailsObj.friendlyName.unescapeHtml4());
                }
            }
        }
	}
	
	/***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    get the list of zuora products
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<SelectOption> getZuoraProducts(){
    	
    	List<SelectOption> lstZuoraProducts=new List<SelectOption>();
		lstZuoraProducts.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
		
		List<zqu__ZProduct__c> lstZProducts = [
            SELECT Id, Name, ProductCountry__c 
            FROM zqu__ZProduct__c 
            WHERE zqu__Deleted__c = false 
            LIMIT 999
        ];
		
		if(!lstZProducts.isEmpty()){
			for(zqu__ZProduct__c zuoraProd : lstZProducts ){
				lstZuoraProducts.add(new SelectOption(zuoraProd.id,zuoraProd.Name));
				mapProductIdProductName.put(zuoraProd.id,zuoraProd.Name);
				mapProductIdProductRegion.put(zuoraProd.id,zuoraProd.ProductCountry__c);
				
				if(!mapProductNameProductRegion.containsKey(zuoraProd.Name)){
					mapProductNameProductRegion.put(zuoraProd.Name,zuoraProd.ProductCountry__c);
				}
			}
		}
		
		return lstZuoraProducts;
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    get the list of possible frequencies
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<SelectOption> getPossibleFrequencyValues(){
    	
    	List<SelectOption> lstFrequency=new List<SelectOption>();
    	lstFrequency.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
    	lstFrequency.add(new SelectOption(Constants.RATE_PLAN_MONTHLY,Constants.RATE_PLAN_MONTHLY));
    	lstFrequency.add(new SelectOption(Constants.RATE_PLAN_ANNUAL,Constants.RATE_PLAN_ANNUAL));
    	return lstFrequency;
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Edit a price plan Rule
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void editPricePlanRule(){
    	displayEditSection = true;
    	lstAlternativeOffers = new List<AlternativeOfferClass>();
    	pricePlanDefaultOffer = new Price_Plan_Offer__c();
    	pricePlanRuleObj = new Price_Plan__c();
    	
    	List<Price_Plan__c> lstPricePlan = getPricePlans();
    	
    	if(!lstPricePlan.isEmpty()){
    		pricePlanRuleObj = lstPricePlan[0];
    		
    		getlstDefaultOfferCodes();
    		
    		if(!pricePlanRuleObj.Price_Plan_Offers__r.isEmpty()){
    			for(Price_Plan_Offer__c pricePlanOfferObj : pricePlanRuleObj.Price_Plan_Offers__r){
    				if(pricePlanOfferObj.Default_Offer__c){
    					pricePlanDefaultOffer=pricePlanOfferObj;
    				}else{
    					AlternativeOfferClass alternativeOfferObj=new AlternativeOfferClass();
    					alternativeOfferObj.alternativeOfferCode=pricePlanOfferObj.Offer_Code__c;
    					lstAlternativeOffers.add(alternativeOfferObj);
    				}
    			}
    		}
    	}   	
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Clone Price Plan Rule
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void clonePricePlanRule(){
    	displayEditSection = true;
    	pricePlanRuleObj = new Price_Plan__c();
    	pricePlanDefaultOffer = new Price_Plan_Offer__c();
    	lstAlternativeOffers = new List<AlternativeOfferClass>();
		
		List<Price_Plan__c> lstPricePlan = getPricePlans();
    	
    	if(!lstPricePlan.isEmpty()){
    		pricePlanRuleObj=lstPricePlan[0].clone(false,true,false,false);
    		
    		getlstDefaultOfferCodes();
    		
    		if(!pricePlanRuleObj.Price_Plan_Offers__r.isEmpty()){
    			for(Price_Plan_Offer__c pricePlanOfferObj : pricePlanRuleObj.Price_Plan_Offers__r){
    				if(pricePlanOfferObj.Default_Offer__c){
    					pricePlanDefaultOffer=pricePlanOfferObj;
    				}else{
    					AlternativeOfferClass alternativeOfferObj=new AlternativeOfferClass();
    					alternativeOfferObj.alternativeOfferCode=pricePlanOfferObj.Offer_Code__c;
    					lstAlternativeOffers.add(alternativeOfferObj);
    				}
    			}
    		}
    	}
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Delete Price Plan Rule
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void deletePricePlanRule(){
    	try{
	    	List<Price_Plan__c> lstPricePlan = getPricePlans();
	    	
	    	if(!lstPricePlan.isEmpty()){
	    		delete lstPricePlan;
	    	}
    	}catch(Exception ex){
    		System.debug('Exception Occurred in function DeletePricePlanRule:' + ex);
    	}
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         26/04/2016
    * Function:  get a list of price plans although it should only return a single record
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    private List<Price_Plan__c> getPricePlans(){
        return [
            SELECT Id, Name, 
                Email_Template__c, 
                Frequency__c, 
                High_Price__c, 
                Low_Price__c,
                Product_From__c, 
                Product_To__c, 
                Plan__c, 
                Renewal_Price__c, 
                No_Price_Change__c, 
                (
                    SELECT Offer_Code__c, 
                        Default_Offer__c, 
                        Offer_Friendly_Name__c 
                    FROM Price_Plan_Offers__r
                )
            FROM Price_Plan__c 
            WHERE Id = :selectedPricePlanRuleId
        ];
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Add New Price Plan Rule Record
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void addNewPricePlanRule(){
    	displayEditSection = true;
    	pricePlanRuleObj = new Price_Plan__c();
    	pricePlanRuleObj.Plan__c = planObj.id;
    	pricePlanDefaultOffer = new Price_Plan_Offer__c();
    	lstAlternativeOffers = new List<AlternativeOfferClass>();
		
		pricePlanDefaultOffer.Default_Offer__c	= true;
	}
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Save Price Plan Rule Changes
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Gavin Palmer        1.1         27/04/2016 - added exception handling
    Gavin Palmer        1.2         03/05/2016 - conditionally add the default offer
    ****************************************************************************************/
    public void savePricePlanRuleChanges(){
    	// roll back the save if any one fails 
    	Savepoint sp = Database.setSavepoint();
        Database.UpsertResult upsertResult;

    	try{
            if(isValidPricePricePlanRule()){

        		List<Price_Plan_Offer__c> lstInsertPricePlanOffers = new List<Price_Plan_Offer__c>();

    	    	//insert the price plan if new or update if it already exists
    	    	upsertResult = Database.upsert(pricePlanRuleObj);
    	    	
	    		List<Price_Plan_Offer__c> lstPricePlanOffers = [
                    SELECT Id, Name 
                    FROM Price_Plan_Offer__c 
                    WHERE Price_Plan__c = :pricePlanRuleObj.Id
                ];
	    		if(!lstPricePlanOffers.isEmpty()){
	    			delete lstPricePlanOffers;
	    		}
    	    	
    	    	//insert the price plan offers
                if(!pricePlanRuleObj.No_Price_Change__c){
        	    	Price_Plan_Offer__c insertDefaultOfferObj = new Price_Plan_Offer__c();
        	    	insertDefaultOfferObj.Price_Plan__c = pricePlanRuleObj.id;
                    insertDefaultOfferObj.Offer_Code__c = pricePlanDefaultOffer.Offer_Code__c;
        	    	insertDefaultOfferObj.Offer_Friendly_Name__c = mapOfferCodeOfferName.get(pricePlanDefaultOffer.Offer_Code__c);
        	    	insertDefaultOfferObj.Default_Offer__c = true;
        	    	lstInsertPricePlanOffers.add(insertDefaultOfferObj);
                }
    	    	
    	    	for(AlternativeOfferClass alternativeOfferObj : lstAlternativeOffers){
    	    		if(!alternativeOfferObj.isDeleted && mapOfferCodeOfferName.containsKey(alternativeOfferObj.alternativeOfferCode)){
    		    		Price_Plan_Offer__c offerObj = new Price_Plan_Offer__c();
    		    		offerObj.Price_Plan__c = pricePlanRuleObj.id;
    		    		offerObj.Offer_Code__c = alternativeOfferObj.alternativeOfferCode;
    		    		offerObj.Offer_Friendly_Name__c = mapOfferCodeOfferName.get(alternativeOfferObj.alternativeOfferCode);
    		    		lstInsertPricePlanOffers.add(offerObj);
    	    		}
    	    	}
    	    	
    	    	if(!lstInsertPricePlanOffers.isEmpty()){
    	    		insert lstInsertPricePlanOffers;
    	    	}
    	    	
    	    	getlstPricePlanRules();

                // hide the section if everything saves correctly
                displayEditSection = false;
            }
	    	
    	}catch(Exception exObj){
    		System.debug('Exception : ' + exObj);
            if(upsertResult != null && upsertResult.isCreated()) pricePlanRuleObj.Id = null;
    		Database.rollback(sp);
            // an error will be put to the page from the exception as well
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  Label.Price_Plan_Clone_Save_Error));
    	}
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Validate the required fields on the page
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    private Boolean isValidPricePricePlanRule(){

        if(String.isEmpty(pricePlanRuleObj.Product_From__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Product_Error));
        }

        if(String.isEmpty(pricePlanRuleObj.Frequency__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Frequency_Error));
        }

        if(pricePlanRuleObj.Low_Price__c < 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Low_Price_Error));
        } else if(pricePlanRuleObj.Low_Price__c > pricePlanRuleObj.High_Price__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Range_Error));
        }

        if(pricePlanRuleObj.High_Price__c < 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_High_Price_Error));
        }

        if(String.isEmpty(pricePlanDefaultOffer.Offer_Code__c) && !pricePlanRuleObj.No_Price_Change__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Price_Plan_Default_Offer_Error));
        }

        if(ApexPages.hasMessages()) {
            return false;
        }

        return true;
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    Cancel Price Plan Rule Changes
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void cancelPricePlanRuleChanges(){
    	displayEditSection	=	false;
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  Redirect to the original record
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    public PageReference returnToDetailPage(){
        PageReference planRecordPage = new PageReference('/' + planId);
        planRecordPage.setRedirect(true);
        return planRecordPage;
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        18/04/2016
    Function    get the price plan rules records
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<Price_Plan__c> getlstPricePlanRules(){  	
    	return [
            SELECT Name, 
                Frequency__c, 
                Low_Price__c, 
                High_Price__c, 
                Product_From__c,
                No_Price_Change__c, 
                Renewal_Price__c 
			FROM Price_Plan__c 
			WHERE Plan__c = :planId
        ];
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        13/04/2016
    Function    get the plan details 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void getPlanDetails(){
    	List<Plan__c> lstPlanDetails = [
            SELECT Id, Name, Days_Before__c, Description__c, Is_Valid__c, Product__c
    		FROM Plan__c 
            WHERE id = :planId
        ];
    	
    	if(!lstPlanDetails.isEmpty()){
    		planObj = lstPlanDetails[0];
    	}
    }
	
	/***************************************************************************************
    Developer   Sally ElGhoul
    Date        15/04/2016
    Function    get the possible default offers based on the price plan selected product and frequency
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Gavin Palmer        1.1         03/05/2016 - if we have no price change just give the none picklist value
    ****************************************************************************************/
    public List<SelectOption> getlstDefaultOfferCodes(){
    	List<SelectOption> lstDefaultOfferCodes=new List<SelectOption>();
    	lstDefaultOfferCodes.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
    	
    	if(!String.isEmpty(pricePlanRuleObj.Product_From__c) && !String.isEmpty(pricePlanRuleObj.Frequency__c) && !pricePlanRuleObj.No_Price_Change__c){
	    	for(CoreApiResources.CoreApiOfferDetails offerDetailsObj: allOffersObj.offers){
	    		if(offerDetailsObj.product==mapProductIdProductName.get(pricePlanRuleObj.Product_From__c) &&  pricePlanRuleObj.Frequency__c.contains(offerDetailsObj.frequency)){
					lstDefaultOfferCodes.add(new SelectOption(offerDetailsObj.tmgId,offerDetailsObj.friendlyName.unescapeHtml4()+' - '+offerDetailsObj.product));
				}
	    	}
    	}
    	
    	return lstDefaultOfferCodes;
	}
	
	/***************************************************************************************
    Developer   Sally ElGhoul
    Date        15/04/2016
    Function    get the possible default offers based on the price plan selected product and frequency
    ******************* Change Log *******************
    Modified by         Version     Change Date
	****************************************************************************************/
    public List<SelectOption> getlstAllAvailableOffers(){
    	List<SelectOption> lstAllOfferCodes=new List<SelectOption>();
    	lstAllOfferCodes.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
    	
    	for(CoreApiResources.CoreApiOfferDetails offerDetailsObj : allOffersObj.offers){
    		if(mapProductIdProductRegion.containsKey(pricePlanRuleObj.Product_From__c) && mapProductNameProductRegion.containsKey(offerDetailsObj.product)){
    			if(mapProductIdProductRegion.get(pricePlanRuleObj.Product_From__c) == mapProductNameProductRegion.get(offerDetailsObj.product)){
		    		lstAllOfferCodes.add(new SelectOption(offerDetailsObj.tmgId,offerDetailsObj.friendlyName.unescapeHtml4()+' - '+offerDetailsObj.product));
    			}
    		}
		}
    	return lstAllOfferCodes;
	}
	
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        Unknown
    Function    add a new alternative offer to the page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public void addAlternativeOffer(){
		lstAlternativeOffers.add(new AlternativeOfferClass());
	}
	
    /***************************************************************************************
    Developer   Sally ElGhoul
    Date        Unknown
    Function    remove a new alternative offer from the page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public void removeAlternativeOffer(){
		List<AlternativeOfferClass> lstRemainingAlternativeOffers=new list<AlternativeOfferClass>();
		
		for(AlternativeOfferClass offerObj: lstAlternativeOffers){
			if(!offerObj.isDeleted){
				lstRemainingAlternativeOffers.add(offerObj);
			}
		}
		
		lstAlternativeOffers=lstRemainingAlternativeOffers;
	}
	
	/***************************************************************************************
    Developer   Sally ElGhoul
    Date        Unknown
    Function    A wrapper class for the alternative offers used on the page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public class AlternativeOfferClass{
		public String  alternativeOfferCode	{get;set;}
		public Boolean isDeleted			{get;set;}
		
		public AlternativeOfferClass(){
			isDeleted=false;
		}
	}
}