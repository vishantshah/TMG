public with sharing class PricingOptionTriggerHandler {

	private boolean AlreadyProcessed = false;

	private static PricingOptionTriggerHandler instance = null;
	
	public static PricingOptionTriggerHandler getInstance(){
		
		if(instance == null){
			instance = new PricingOptionTriggerHandler();
		}
		
		return instance;
		
	}

	public void OnBeforeInsert(list<Pricing_Options__c> newPricingOptions){
		assignFulfillmentPlan(newPricingOptions);
	}

	public void OnBeforeUpdate(list<Pricing_Options__c> newPricingOptions){
		system.debug('***AlreadyProcessed: ' + AlreadyProcessed);
		assignFulfillmentPlan(newPricingOptions);
	}

	private void assignFulfillmentPlan(list<Pricing_Options__c> newPricingOptions){
		/*
		Because this uses the singleton pattern,  when you insert a record in a test,  you cannot 
		trigger the update code afterwards because this has already run(!)
		Therefore,  always run this code if a test is in progress
		*/
		if(!AlreadyProcessed || Test.isRunningTest()){
			//Get the FulfillmentPlans
			map<string, id> plans = new map<string, id>();
			for(FulfillmentPlan__c plan : [select Id, ProductType__c from FulfillmentPlan__c]){
				plans.put(plan.ProductType__c.toLowerCase(), plan.Id);
			}
			system.debug('***plans: ' + plans);
			
			//Use the product type on the pricing option to assign the fulfillment plan
			if(!plans.isEmpty()){
				for(Pricing_Options__c pricingOption : newPricingOptions){
					if(pricingOption.Product_Type__c != null){
						pricingOption.FulfillmentPlanId__c = plans.get(pricingOption.Product_Type__c.toLowerCase());
					}
				}
			}
			
			AlreadyProcessed = true;
		}
		
	}

}