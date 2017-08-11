/**
* Author:       Sally ElGhoul (Accenture)
* Date:         27/08/2015
* Description:  Trigger handler for Zuora QuoteRatePlan Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
public class ZQuoteRatePlanTriggerHandler {
	
	private static ZQuoteRatePlanTriggerHandler instance;
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        27/08/2015
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZQuoteRatePlanTriggerHandler getInstance() {
        if (instance == null) instance = new ZQuoteRatePlanTriggerHandler();
        return instance; 
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        27/08/2015
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterInsert(zqu__QuoteRatePlan__c[] newQuoteRatePlans,map<id,zqu__QuoteRatePlan__c> newQuoteRatePlansMap){
    	//call this function to fill the quote field of subscription type either anuual or monthly
    	FillQuoteSubscriptionType(newQuoteRatePlans);
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        14/01/2016
    Function    this function is called to handle on before insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnBeforeInsert(zqu__QuoteRatePlan__c[] newQuoteRatePlans){
    	//validate that only one product is allowed on the quote
    	ValidateNumberOfProducts(newQuoteRatePlans);
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        27/08/2015
    Function    this function is called to fill the quote subscription type
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void FillQuoteSubscriptionType(zqu__QuoteRatePlan__c[] newQuoteRatePlans){
    	
    	set<id> setQuoteIds=new set<id>();
    	map<id,string> mapQuoteSubscriptionType=new map<id,string>();
    	
    	for(zqu__QuoteRatePlan__c quoteRatePlanObj : newQuoteRatePlans){
    		
    		//we need to check that the amendment type is new product
    		if(quoteRatePlanObj.zqu__AmendmentType__c==constants.RATE_PLAN_NEW_PRODUCT_AMENDMENT_TYPE){
    			if(!quoteRatePlanObj.Name.contains(constants.DISCOUNT_RATE_PLAN_NAME)){
	    			setQuoteIds.add(quoteRatePlanObj.zqu__Quote__c);
	    			
	    			//if the rate plan is monthly , we need to mark the quote to be monthly
	    			if(quoteRatePlanObj.Name.tolowerCase().contains(constants.RATE_PLAN_MONTHLY.tolowerCase())){
	    				mapQuoteSubscriptionType.put(quoteRatePlanObj.zqu__Quote__c,constants.RATE_PLAN_MONTHLY);
	    			}else{ //if the rate plan is annual , we need to mark the wuote to be annual
	    				mapQuoteSubscriptionType.put(quoteRatePlanObj.zqu__Quote__c,constants.RATE_PLAN_ANNUAL);
	    			}
    			}
    		}	
    	}
    	
    	//query the quotes and update the subscription tern type values to show the type of quote either annual or monthly
    	if(setQuoteIds!=null && setQuoteIds.size()>0){
    		
    		//query the quotes
    		list<zqu__Quote__c> lstUpdateQuotes=[select id,Subscription_Rate_Plan_Term_Type__c from zqu__Quote__c where id in :setQuoteIds];
    		
    		if(lstUpdateQuotes!=null && lstUpdateQuotes.size()>0){
    			for(zqu__Quote__c quoteObj : lstUpdateQuotes){
    				//update the quote subscription term type using the map values
    				if(mapQuoteSubscriptionType.containskey(quoteObj.id)){
    					quoteObj.Subscription_Rate_Plan_Term_Type__c=mapQuoteSubscriptionType.get(quoteObj.id);
    				}
    			}
    			
    			//update the quotes
    			update lstUpdateQuotes;
    		}
    	}
    }
    
     /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        14/01/2016
    Function    this function is called to validate that only one product is allowed on the quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void ValidateNumberOfProducts(zqu__QuoteRatePlan__c[] newQuoteRatePlans){
    	
    	//set of quote ids newly created by the trigger
    	set<id> setQuoteIds=new set<id>();
    	
    	//set of quote ids that already have product added already to it
    	set<id> setQuotesWithProduct=new set<id>();
    	
    	//set of quote ids that threw an error
    	//I have created this set to avoid throwing the same error twice if a new quote has two quote rate plans (products)
    	//we want the error to be thrown just once
    	set<id> setQuoteWithErrorsIds=new set<id>();
    	
    	//fill set of quote Ids by looping on the quotes of the quote rate plans list
    	for(zqu__QuoteRatePlan__c quoteRatePlanObj : newQuoteRatePlans){
    		//skip the discount rate plans, they will be added no need to check the number of products for them
    		if(quoteRatePlanObj.name!=constants.DISCOUNT_RATE_PLAN_NAME){
	    		if(!setQuoteIds.contains(quoteRatePlanObj.zqu__Quote__c)){
	    			setQuoteIds.add(quoteRatePlanObj.zqu__Quote__c);
	    		}else{
	    			//this condition to catch the case that a new quote has two products to start with
	    			if(!setQuotesWithProduct.contains(quoteRatePlanObj.zqu__Quote__c)){
	    				setQuotesWithProduct.add(quoteRatePlanObj.zqu__Quote__c);
	    			}
	    		}
    		}
    	}
    	
    	//check if the the quotes have products added already
    	list<zqu__QuoteRatePlan__c> lstExistingQuoteRatePlans=
    								[select zqu__Quote__c,id from zqu__QuoteRatePlan__c 
    									where zqu__Quote__c in :setQuoteIds 
    									and name!=:constants.DISCOUNT_RATE_PLAN_NAME];
    		
    	//fill the set of quote ids with products							
    	if(lstExistingQuoteRatePlans!=null && lstExistingQuoteRatePlans.size()>0){
			for(zqu__QuoteRatePlan__c quoteRatePlanObj : lstExistingQuoteRatePlans){
				if(!setQuotesWithProduct.contains(quoteRatePlanObj.zqu__Quote__c)){
					setQuotesWithProduct.add(quoteRatePlanObj.zqu__Quote__c);
				}
			}	    		
    	}
    	
    	//loop on the quote rate plans that needs to be inserted and check if the quote rate plan's
    	//quote had already a product, throw an error that the quote can have a single product 
    	for(zqu__QuoteRatePlan__c quoteRatePlanObj : newQuoteRatePlans){
    		if(setQuotesWithProduct.contains(quoteRatePlanObj.zqu__Quote__c) 
    			&& !setQuoteWithErrorsIds.contains(quoteRatePlanObj.zqu__Quote__c) //don't throw an error if an error already thrown for this quote
    			&& quoteRatePlanObj.name!=constants.DISCOUNT_RATE_PLAN_NAME) //don't throw errors for discount rate plans
    			{ 
    				
    			quoteRatePlanObj.addError(Label.Quote_Single_Product_Error_Message);
    			setQuoteWithErrorsIds.add(quoteRatePlanObj.zqu__Quote__c);
    		}
    	}
    }
}