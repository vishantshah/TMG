/**
* Author:       Sally ElGhoul (Accenture)
* Date:         21/09/2015
* Description:  Trigger handler for Zuora SubcriptionProductCharge Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Michal Kwika		01/12/2015
* Michal Szewczyk   01/02/2016 -added new method updateProductOnAccount()
* Michal Szewczyk   23/02/2016 -added new method calculateSubSummaryFields()
* Michal Szewczyk   09/03/2016 - fix for Mid Term Discount in calculateSubSummaryFields()
* Michal Szewczyk   10/03/2016 - Exclude manual refund in calculateSubSummaryFields()
* Gavin Palmer      31/05/2016 - added conditions into calculateSubSummaryFields()
* Gavin Palmer      21/06/2016 - modified conditions in calculateSubSummaryFields()
* Gavin Palmer      24/06/2016 - reworking of calculateSubSummaryFields()
* Michal Szewczyk   22/08/2016 - reworking of calculateSubSummaryFields()
* Pawel Chrzanowski 22/02/2017 - added updateRestrictedOfferUsageRecords()
**/
public class ZQuoteSubProductChargeTriggerHandler {
	
	private static ZQuoteSubProductChargeTriggerHandler instance;
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/09/2015
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZQuoteSubProductChargeTriggerHandler getInstance() {
        if (instance == null) instance = new ZQuoteSubProductChargeTriggerHandler();
        return instance; 
    }
	
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/09/2015
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    * Michal Szewczyk   01/02/2016 - invok new method updateProductOnAccount()
    * Michal Szewczyk   01/02/2016 - invoke new method calculateSubSummaryFields()
	* Pawel Chrzanowski 22/02/2017 - added updateRestrictedOfferUsageRecords()
    ****************************************************************************************/
    public void OnAfterInsert(Zuora__SubscriptionProductCharge__c[] newSubscriptionProductCharges,map<id,Zuora__SubscriptionProductCharge__c> newSubscriptionProductChargesMap){
    	//Update the subscription product field with the subscription charge name
    	updateSubscriptionProduct(newSubscriptionProductCharges);
    	updateProductOnAccount(newSubscriptionProductCharges);
        calculateSubSummaryFields(newSubscriptionProductCharges);
        updateRestrictedOfferUsageRecords(newSubscriptionProductCharges);
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/09/2015
    Function    this function is called to handle on after Delete
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterDelete(Zuora__SubscriptionProductCharge__c[] oldSubscriptionProductCharges, Map<ID, Zuora__SubscriptionProductCharge__c> OldSubscriptionProductChargesMap){
    	
    	//Clear the subscription Product field
    	clearSubscriptionProduct(oldSubscriptionProductCharges);
    }
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/09/2015
    Function    this function is called to Update the subscription product field with the subscription charge name
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika		1.1			01/12/2015
    ****************************************************************************************/
	private void updateSubscriptionProduct(Zuora__SubscriptionProductCharge__c[] newSubscriptionProductCharges){
		
		set<id> setSubscriptionIds=new set<id>();
		map<id,string> mapSubscriptionIdChargeName=new map<id,string>();
		
		//loop on the subscription product charge to get the subscription Ids and subscription charge names
		for(Zuora__SubscriptionProductCharge__c SubProductChargeObj : newSubscriptionProductCharges){
        	System.debug('### ZQUOTESUB subProductobject :' + subProductChargeObj);

        	if(subProductChargeObj!= null && subProductChargeObj.Name != null && subProductChargeObj.Zuora__Model__c!= null){
        		//filter the subscription product charge , only get the records with flat free pricing and make sure it doens't include in its name discount
        		if(subProductChargeObj.Zuora__Model__c.toLowerCase()==Constants.SUBSCRIPTION_PRODUCTCHARGE_FLAT_FEE_PRICING_VALUE && !subProductChargeObj.name.toLowerCase().contains(constants.SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE)){
	        		if(!setSubscriptionIds.contains(SubProductChargeObj.Zuora__Subscription__c)){
	        			setSubscriptionIds.add(SubProductChargeObj.Zuora__Subscription__c);
	        		}
	        	
	        		if(!mapSubscriptionIdChargeName.containskey(SubProductChargeObj.Zuora__Subscription__c)){
	        			mapSubscriptionIdChargeName.put(SubProductChargeObj.Zuora__Subscription__c,SubProductChargeObj.name);
	        		}
        		}
        	}
        }
        
        if(setSubscriptionIds!=null && setSubscriptionIds.size()>0){
	        //get the subscription record to update them 
	        list<Zuora__Subscription__c> lstSubscriptions=[select id,Subscription_Product__c from Zuora__Subscription__c where id in :setSubscriptionIds];
	        for(Zuora__Subscription__c subscriptionObj : lstSubscriptions){
	        	if(mapSubscriptionIdChargeName.containskey(subscriptionObj.id)){
	        		//update the subscription product field with the chagre name of the subscription product charge record 
	        		subscriptionObj.Subscription_Product__c=mapSubscriptionIdChargeName.get(subscriptionObj.id);
	        	}
	        }
	        
	        //update the subscription records
	        if(lstSubscriptions!=null && lstSubscriptions.size()>0){
	        	update lstSubscriptions;
	        }
        }
	}
   /*************************************************************************************** 
    Developer   Michal Szewczyk
    Date        22/02/2016
    Function    this function is called to populate Ongoing and Initial Prices on Sub
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         10/03/2016  - exclude Refund Rate Charge for manual refund 
    Gavin Palmer        1.2         31/05/2016  - added a condition so that subscription charges that arent in date arent added on
    Gavin Palmer        1.3         21/06/2016  - Improved the condition to include today
    Gavin Palmer        1.4         24/06/2016  - Reworked the method so that it initialises the 2 fields to 0 and then calculates them from all the children product charges, 
                                                    also if effective start date is greater than today then set some fields that will trigger a time dependany workflow
    Michal Szewczyk     1.5         22/08/20166 - removed hidden fields logic for on going/initial price
    ****************************************************************************************/
    private void calculateSubSummaryFields(Zuora__SubscriptionProductCharge__c[] newSubscriptionProductCharges){

        Set<Id> subscriptionIds = new Set<Id>();
        Map<Id,Zuora__Subscription__c> allSubsMap;

        for(Zuora__SubscriptionProductCharge__c subProductChargeObj : newSubscriptionProductCharges){
            subscriptionIds.add(subProductChargeObj.Zuora__Subscription__c);
        }

        allSubsMap = new Map<Id,Zuora__Subscription__c>([Select Id,On_Going_Subscription_Price__c,Initial_Subscription_Price__c,Zuora__ServiceActivationDate__c,Subscription_Rate_Plan_Term_Type__c from Zuora__Subscription__c where Id IN :subscriptionIds]);

        List<Zuora__SubscriptionProductCharge__c> allRelatedProductCharges = [
            SELECT Name, 
                Zuora__Model__c, 
                Zuora__EffectiveStartDate__c, 
                Zuora__EffectiveEndDate__c, 
                Zuora__Price__c, 
                Zuora__Subscription__c, 
                Zuora__Upto_How_Many_Periods__c 
            FROM Zuora__SubscriptionProductCharge__c 
            WHERE Zuora__Subscription__c IN :subscriptionIds
        ];

        Map<Id, List<Zuora__SubscriptionProductCharge__c>> childProductChargesMap = new Map<Id, List<Zuora__SubscriptionProductCharge__c>>();
        for(Zuora__SubscriptionProductCharge__c subProductChargeObj : allRelatedProductCharges){
            if(childProductChargesMap.containsKey(subProductChargeObj.Zuora__Subscription__c)){
                childProductChargesMap.get(subProductChargeObj.Zuora__Subscription__c).add(subProductChargeObj);
            }else{
                childProductChargesMap.put(subProductChargeObj.Zuora__Subscription__c, new List<Zuora__SubscriptionProductCharge__c>{subProductChargeObj});
            }
        }

        for(Zuora__Subscription__c subInContext : allSubsMap.values()){
            Decimal initialPrice = 0.0;
            Decimal onGoingPrice = 0.0;
            Date productChargeDate;

            for(Zuora__SubscriptionProductCharge__c subProductChargeObj : childProductChargesMap.get(subInContext.Id)){
                if(subProductChargeObj.Name != null 
                    && subProductChargeObj.Name != Constants.REFUND_RATE_PLAN_NAME 
                    && subProductChargeObj.Name != Constants.MID_TERM_DISCOUNT_RATE_PLAN_NAME 
                    && subProductChargeObj.Zuora__Model__c!= null
                    && subProductChargeObj.Zuora__EffectiveEndDate__c >= Date.today())
                {
                    Decimal subPrice = subProductChargeObj.Zuora__Price__c != null ? subProductChargeObj.Zuora__Price__c : 0;
                    // assumption here is that there will only ever be one product with an effective start date
                    if(!(subProductChargeObj.Name.toLowerCase().contains(Constants.SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE))) {
                        initialPrice += subPrice;
                        onGoingPrice += subPrice;
                        productChargeDate = subProductChargeObj.Zuora__EffectiveStartDate__c;
                    } else {
                        initialPrice += subPrice;
                    }

                    if(subProductChargeObj.Name.toLowerCase().contains(Constants.SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE) && subProductChargeObj.Zuora__Upto_How_Many_Periods__c >= 12){
                        onGoingPrice += subPrice;
                    }
                    if(subInContext.Subscription_Rate_Plan_Term_Type__c == Constants.RATE_PLAN_ANNUAL) {
                        onGoingPrice = 0;
                    }
                }
            }

                subInContext.Initial_Subscription_Price__c = initialPrice;
                subInContext.On_Going_Subscription_Price__c = onGoingPrice;
        }
        
        try{  
            update allSubsMap.values();
        } catch(Exception e){
            System.debug('TMG:ZQuoteSubProductChargeTriggerHandler:calculateSubSummaryFields:error :' + e);    
        }
    }

	/*************************************************************************************** 
    Developer   Michal Szewczyk
    Date        01/02/2016
    Function    this function is called to Update the product field on account to show current product
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	private void updateProductOnAccount(Zuora__SubscriptionProductCharge__c[] newSubscriptionProductCharges){
		Map<Id,Id> mapAccountIdProuctId = new Map<Id,Id>();
		
		//loop on the subscription product charge to get the subscription Ids and subscription charge names
		for(Zuora__SubscriptionProductCharge__c subProductChargeObj : newSubscriptionProductCharges){
        	System.debug('### ZQUOTESUB subProductobject :' + subProductChargeObj);

        	if(subProductChargeObj!= null && subProductChargeObj.Name != null && subProductChargeObj.Zuora__Model__c!= null){
        		//filter the subscription product charge , only get the records with flat free pricing and make sure it doens't include in its name discount
        		if(subProductChargeObj.Zuora__Model__c.toLowerCase()==Constants.SUBSCRIPTION_PRODUCTCHARGE_FLAT_FEE_PRICING_VALUE && !subProductChargeObj.name.toLowerCase().contains(constants.SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE)){
	        	
	        		if(!mapAccountIdProuctId.containskey(subProductChargeObj.Zuora__Account__c)){
	        			mapAccountIdProuctId.put(subProductChargeObj.Zuora__Account__c,subProductChargeObj.Zuora__Product__c);
	        		}
        		}
        	}
        }

     	if(mapAccountIdProuctId.size() > 0 ) {
     		//fetch Products with externalId which is the same on ZProduct and allow us to buid relation Account -> ZProduct
     		Map<Id,String> mapProductIdToExternalId = new Map<Id,String>();
     		for(Zuora__Product__c product:[SELECT Id,Zuora__External_Id__c FROM Zuora__Product__c WHERE Id IN :mapAccountIdProuctId.values()]){
     			mapProductIdToExternalId.put(product.Id,product.Zuora__External_Id__c);
     		}
     		// fetch all related ZProducts 
     		Map<String,zqu__ZProduct__c> mapIdToZProduct = new Map<String,zqu__ZProduct__c>();
     		for(zqu__ZProduct__c tmp : [SELECT Id,zqu__ZuoraId__c FROM zqu__ZProduct__c WHERE zqu__ZuoraId__c IN :mapProductIdToExternalId.values()]){
     			mapIdToZProduct.put(tmp.zqu__ZuoraId__c,tmp);
     		}

     		List<Account> accountsToUpdate = [SELECT Id,Product__c FROM Account WHERE Id IN :mapAccountIdProuctId.keyset()];
     		for(Account acc : accountsToUpdate) {
 				if(mapIdToZProduct.get(mapProductIdToExternalId.get(mapAccountIdProuctId.get(acc.Id))) != null) {
                    acc.Product__c = mapIdToZProduct.get(mapProductIdToExternalId.get(mapAccountIdProuctId.get(acc.Id))).id;
                }
     		}

     		try{	
	     		update accountsToUpdate;
     		} catch(Exception e){

	     		System.debug('ZQuoteSubProductChargeTriggerHandler : updateProductOnAccount : error :' + e);	
     		}
        }
	}
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        21/09/2015
    Function    this function is called to clear the subscription product field 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	private void clearSubscriptionProduct(Zuora__SubscriptionProductCharge__c[] oldSubscriptionProductCharges){
		
		//set to keep the subscription Ids for the subscription product charges
		set<id> setSubscriptionIds=new set<id>();
		
		//loop on the subscription product Charges to get the subscription ids
		for(Zuora__SubscriptionProductCharge__c subscriptionProductChargeObj : oldSubscriptionProductCharges){
			if(!setSubscriptionIds.contains(subscriptionProductChargeObj.Zuora__Subscription__c)){
				setSubscriptionIds.add(subscriptionProductChargeObj.Zuora__Subscription__c);
			}	
		}
		
		if(setSubscriptionIds!=null && setSubscriptionIds.size()>0){
	        //get the subscription record to update them 
	        list<Zuora__Subscription__c> lstSubscriptions=[select id,Subscription_Product__c from Zuora__Subscription__c where id in :setSubscriptionIds];
	        for(Zuora__Subscription__c subscriptionObj : lstSubscriptions){
	        	//clear the subscription product field
	        	subscriptionObj.Subscription_Product__c='';
	        }
	        
	        //update subscriptions
	        if(lstSubscriptions!=null && lstSubscriptions.size()>0){
				update lstSubscriptions;
			}
		}  
	}

	/*************************************************************************************** 
    Developer: Pawel Chrzanowski
    Date: 22/02/2017
    Function to update related blank ROU records created by API after online acquisition
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void updateRestrictedOfferUsageRecords(List<Zuora__SubscriptionProductCharge__c> newSubscriptionProductCharges){
        List<Restricted_Offer_Usage__c> rouToUpdate = new List<Restricted_Offer_Usage__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> zuoraProductIds = new Set<Id>();
        Set<String> zquProductIds = new Set<String>();
        Set<Id> subIds = new Set<Id>();

        for(Zuora__SubscriptionProductCharge__c spc : newSubscriptionProductCharges){
            if(spc.Name.contains(Constants.DISCOUNT_RATE_PLAN_NAME.tolowerCase())) continue;
            accountIds.add(spc.Zuora__Account__c);
            zuoraProductIds.add(spc.Zuora__Product__c);
            subIds.add(spc.Zuora__Subscription__c);
        }

        List<Zuora__Product__c> lstZuoraProducts = [SELECT Zuora__External_Id__c FROM Zuora__Product__c WHERE Id IN :zuoraProductIds];
        for(Zuora__Product__c prod : lstZuoraProducts){
            zquProductIds.add(prod.Zuora__External_Id__c);
        }

        Map<String, Id> productZuoraIdIdMap = new Map<String, Id>();
        List<zqu__ZProduct__c> lstZquProducts = [SELECT zqu__ZuoraId__c FROM zqu__ZProduct__c WHERE zqu__ZuoraId__c IN :zquProductIds];
        for(zqu__ZProduct__c prod : lstZquProducts){
            productZuoraIdIdMap.put(prod.zqu__ZuoraId__c, prod.Id);
        }

        Map<String, Id> subZuoraIdIdMap = new Map<String, Id>();
        List<Zuora__Subscription__c> lstSubs = [SELECT Zuora__External_Id__c FROM Zuora__Subscription__c WHERE Id IN :subIds];
        for(Zuora__Subscription__c sub : lstSubs){
            subZuoraIdIdMap.put(sub.Zuora__External_Id__c, sub.Id);
        }

        List<Restricted_Offer_Usage__c> lstROU = [SELECT Product__c, Zuora_Product_Id__c, Subscription__c, Zuora_Subscription_Id__c FROM Restricted_Offer_Usage__c WHERE Account__c IN :accountIds];
        for(Restricted_Offer_Usage__c rou : lstROU){
            Boolean isChanged = false;
            if(rou.Product__c == null && String.isNotEmpty(rou.Zuora_Product_Id__c)){
                rou.Product__c = productZuoraIdIdMap.get(rou.Zuora_Product_Id__c);
                isChanged = true;
            }
            if(rou.Subscription__c == null && String.isNotEmpty(rou.Zuora_Subscription_Id__c)){
                rou.Subscription__c = subZuoraIdIdMap.get(rou.Zuora_Subscription_Id__c);
                isChanged = true;
            }
            if(isChanged){
                rouToUpdate.add(rou);
            }
        }

        System.debug('### updateRestrictedOfferUsageRecords rouToUpdate size: ' + rouToUpdate.size());
        if(rouToUpdate.isEmpty()) return;

        Database.SaveResult[] lstResults = Database.update(rouToUpdate, false);
        for(Integer i=0; i<lstResults.size(); i++){
            if(!lstResults[i].isSuccess()){
                for(Database.Error er : lstResults[i].getErrors()){
                    System.debug('Error inserting Restricted Offer Usage record: '+ er.getMessage());
                }
            }
        }
    }
}