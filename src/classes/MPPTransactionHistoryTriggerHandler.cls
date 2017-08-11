/**
* @author Unknown
* @date Unknown
* @description Handler class for MPPTransactionHistoryTrigger trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         29/07/2015  //added singleton pattern, moved action methods from MPPTransactionHistoryTriggerActions
**/
public class MPPTransactionHistoryTriggerHandler {

	private static MPPTransactionHistoryTriggerHandler instance;
    public Boolean isExecuting = false;
				
    public static MPPTransactionHistoryTriggerHandler getInstance() {
        if (instance == null) instance = new MPPTransactionHistoryTriggerHandler();
        return instance; 
    }

	public void OnBeforeInsert(MPP_Transaction_History__c[] newMPPTransactionHistories){
		 if (!this.isExecuting){
            this.isExecuting = true;

		 	this.CalculateVAT(newMPPTransactionHistories);

		  	this.isExecuting = false;        
        }
	}
	
	public void OnAfterInsert(MPP_Transaction_History__c[] newMPPTransactionHistories){
		if (!this.isExecuting) {
        	this.isExecuting = true;
			
			this.UpdateDeferredRevenue(newMPPTransactionHistories);
			this.UpdateSubscriptionDetails(newMPPTransactionHistories);

			this.isExecuting = false;        
        }
	}
	
	public void OnBeforeUpdate(MPP_Transaction_History__c[] oldMPPTransactionHistories, MPP_Transaction_History__c[] updatedMPPTransactionHistories, Map<ID, MPP_Transaction_History__c> MPPTransactionHistoryMap){
		if (!this.isExecuting) {
        	this.isExecuting = true;

			this.CalculateVAT(updatedMPPTransactionHistories);

			this.isExecuting = false;        
        }
	}
	
	public void OnAfterUpdate(MPP_Transaction_History__c[] oldMPPTransactionHistories, MPP_Transaction_History__c[] updatedMPPTransactionHistories, Map<ID, MPP_Transaction_History__c> OldMPPTransactionHistoryMap, Map<ID, MPP_Transaction_History__c> NewMPPTransactionHistoryMap){
		if (!this.isExecuting) {
        	this.isExecuting = true;

			this.UpdateDeferredRevenue(updatedMPPTransactionHistories);
			this.UpdateSubscriptionDetails(updatedMPPTransactionHistories);

			this.isExecuting = false;        
        }
	}
	
	public void OnBeforeDelete(MPP_Transaction_History__c[] MPPTransactionHistoriesToDelete, Map<ID, MPP_Transaction_History__c> MPPTransactionHistoryMap){}
	
	public void OnAfterDelete(MPP_Transaction_History__c[] deletedMPPTransactionHistories, Map<ID, MPP_Transaction_History__c> MPPTransactionHistoryMap){
		if (!this.isExecuting) {
        	this.isExecuting = true;

			this.UpdateDeferredRevenue(deletedMPPTransactionHistories);

			this.isExecuting = false;        
        }
	}
	
	
	public void OnUndelete(MPP_Transaction_History__c[] restoredMPPTransactionHistories){
		if (!this.isExecuting) {
        	this.isExecuting = true;

			this.UpdateDeferredRevenue(restoredMPPTransactionHistories);

			this.isExecuting = false;        
        }
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - Update the deferred revenue for the premium subscriptions that these transactions relate to
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         18/06/2015  //modified the way how DeferredCalculation is called 
	****************************************************************************************/
	public void UpdateDeferredRevenue(List<MPP_Transaction_History__c> MPPTransactionHistories){
	
		if (DeferredCalculation.isTestScenario == null) {DeferredCalculation.isTestScenario = false;}
		if (DeferredCalculation.inDeferredCalc == null) {DeferredCalculation.inDeferredCalc = false;}
		
		if (DeferredCalculation.isTestScenario || DeferredCalculation.inDeferredCalc) 
			return;
	
		DeferredCalculation.inDeferredCalc = true;
		DeferredCalculation.DeferredRevenueCalc calc = new DeferredCalculation.DeferredRevenueCalc();
	
		Set<Id> subIds = new Set<Id>();
		for (MPP_Transaction_History__c txn : MPPTransactionHistories) {
			if(txn.Subscription__c != null && !subIds.contains(txn.Subscription__c)) {
				subIds.add(txn.Subscription__c);
			}
		}	
		
		calc.addSubsForProcessing(subIds);
		calc.GetSubData();
		calc.Calculate();
		calc.UpdateValues();
		DeferredCalculation.inDeferredCalc = false;
	}		
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - Manage the changing of the subscription state (premium and digital) based on the status of the 
		transaction being written
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         30/07/2015  //modified so that accounts updated based on nested method calls are unique (previously list uniqueness error)
	****************************************************************************************/
	public void UpdateSubscriptionDetails(List<MPP_Transaction_History__c> MPPTransactionHistories){

		Set<MPP_Transaction_History__c> digiOK = new Set<MPP_Transaction_History__c>();
		Set<MPP_Transaction_History__c> digiFail = new Set<MPP_Transaction_History__c>();
		Set<MPP_Transaction_History__c> premOK = new Set<MPP_Transaction_History__c>();
		Set<MPP_Transaction_History__c> premFail = new Set<MPP_Transaction_History__c>();
		
		for(MPP_Transaction_History__c txn : MPPTransactionHistories){

			if(txn.DD_Transaction_Type__c == 'AUDDIS')
				continue;
				
			// Digital subscribers don't have subscription records
			if(txn.Subscription__c == null){
				if(txn.Payment_status__c == 'failed')
					digiFail.add(txn);
				if(txn.Payment_status__c == 'success' || txn.Payment_status__c == 'pending' )
					digiOK.add(txn);
			} else {
				if(txn.Payment_status__c == 'failed')
					premFail.add(txn);
				if(txn.Payment_status__c == 'success')
					premOK.add(txn);
			}
		}
		
		Map<Id, Account> mapUpdateSubscribers = new Map<Id, Account>();
		List<Subscription__c> updateSubscriptionsNoLock = new List<Subscription__c>();
		List<Subscription__c> updateSubscriptionsWithLock = new List<Subscription__c>();
		Set<Id> subscriptionIdsToUpdate = new Set<Id>();
		
		if(!digiFail.isEmpty()){
			processDigitalFailures(digiFail, mapUpdateSubscribers);
		}
		
		if(!digiOK.isEmpty()){
			processDigitalSuccesses(digiOK, mapUpdateSubscribers);
		}
		
		if(!premFail.isEmpty()){
			processPremiumFailures(premFail, updateSubscriptionsNoLock);
		}
				
		if(!premOK.isEmpty()){
			processPremiumSuccesses(premOK, updateSubscriptionsNoLock, updateSubscriptionsWithLock);
		}

		// Actually do the updates
		update mapUpdateSubscribers.values();
		update updateSubscriptionsNoLock;
		
		SubscriptionTriggerHandler.getInstance().bDeferredCalculationSkip = true;
		update updateSubscriptionsWithLock;
		SubscriptionTriggerHandler.getInstance().bDeferredCalculationSkip = false;

	}
	
	/** Calculate the VAT due on each transaction
	 ** Added Change for PP-1317 
	*/
	public void CalculateVAT(List<MPP_Transaction_History__c> MPPTransactionHistories){
		VAT__c vat = VAT__c.getInstance('VAT');
		List<MPP_Transaction_History__c> premiumTxns = new List<MPP_Transaction_History__c>();
		List<MPP_Transaction_History__c> digitalTxns = new List<MPP_Transaction_History__c>();
		List<MPP_Transaction_History__c> failedTXns = new List<MPP_Transaction_History__c>();
		Set<Id> subscriptionIds = new Set<Id>();
		Set<Id> subscriberIds = new Set<Id>();
		// Change start for PP-1317
		// Find All Failed and Cancelled Tarnsaction
		for(MPP_Transaction_History__c txn : MPPTransactionHistories){
			if(txn.DD_Transaction_Type__c == 'AUDDIS'){
				continue;
			}

			if(txn.Payment_status__c == 'Failed' || txn.Payment_status__c == 'Cancelled')	{
				failedTXns.add(txn);
			} else {
				subscriberIds.add(txn.Subscriber__c);
				if(txn.Subscription__c != null){
					premiumTxns.add(txn);
					subscriptionIds.add(txn.Subscription__c);
				}else {
					digitalTxns.add(txn);
				}
		  	}
		}
		
		Map<Id, Subscription__c> subscriptions = new Map<Id, Subscription__c>([SELECT Id, WeeklyDigitalVAT__c, WeeklyPrintPrice__c, Weekly_Price__c, Digital_VAT_Rate__c FROM Subscription__c WHERE Id IN :subscriptionIds]);
		Map<Id, Account> subscribers = new Map<Id, Account>([SELECT Id, PersonMailingCountry FROM Account WHERE Id IN :subscriberIds]); 
		
		for(MPP_Transaction_History__c txn : failedTXns){
			txn.Total_Price__c=0;
			txn.Net_Amount__c = 0;
			txn.VAT_Amount__c = 0;
			
		}
		
		//End Change PP-1317
		
		for(MPP_Transaction_History__c txn : premiumTxns){
			if(Trigger.isBefore && Trigger.isInsert){
				String country = subscribers.get(txn.subscriber__c).PersonMailingCountry;
				String isoCode = (TMGUtil.isDataValid(country) ? country.toUpperCase() : null);
				Boolean hasCountryMap = Country_Codes__c.getAll().containsKey(isoCode);
				
				if(hasCountryMap){
					Country_Codes__c c = Country_Codes__c.getInstance(isoCode);
					txn.VAT_Country__c = c.Country_Name__c;
				}
			}
			txn.VAT_Type__c = 'UK Zero';
			txn.VAT_Rate__c = 0;
			txn.Net_Amount__c = txn.Total_Price__c - txn.VAT_Rate__c;
			txn.VAT_Amount__c = txn.Total_Price__c * txn.VAT_Rate__c;
		}
		
		for(MPP_Transaction_History__c txn : digitalTxns){
			/* For digital subscriptions the VAT is calculated based on the
				prevailing VAT rates at the time the transaction is taken
			*/
			// get country and vat rate
			if(!subscribers.containsKey(txn.Subscriber__c))
				continue;
			
			Decimal vatRate;
			String country = subscribers.get(txn.subscriber__c).PersonMailingCountry;
			String isoCode = (TMGUtil.isDataValid(country) ? country.toUpperCase() : null);
			Boolean hasCountryMap = Country_Codes__c.getAll().containsKey(isoCode);
			
			if(hasCountryMap){
				Country_Codes__c c = Country_Codes__c.getInstance(isoCode);
				if(Trigger.isBefore && Trigger.isInsert){
					txn.VAT_Country__c = c.Country_Name__c;
				}
				
				if(c.Name == 'GB'){
					vatRate = vat.UK_Standard_VAT_Rate__c;
					txn.VAT_Type__c = 'UK Standard';
				} else if(c.EU__c){
					vatRate = vat.EU_Standard_VAT_Rate__c;
					txn.VAT_Type__c = 'EU Standard';
				} else{
					vatRate = 0;
					txn.VAT_Type__c = 'Non EU Exempt';
				}
			}else{
				vatRate = 0;
				txn.VAT_Type__c = 'Non EU Exempt';
			}

			txn.VAT_Rate__c = vatRate;
			if( txn.Total_Price__c != null ){
				txn.Net_Amount__c = TMGUtil.decimalRound(txn.Total_Price__c / (1+(vatRate/100)), 2);
				txn.VAT_Amount__c = txn.Total_Price__c - txn.Net_Amount__c;
			}
		}
	}
	
	/** Process the failed transactions for digital accounts
	*/
	private void processDigitalFailures(Set<MPP_Transaction_History__c> transactions, Map<Id, Account> mapUpdateSubscribers){
		for(MPP_Transaction_History__c txn : transactions){
			if(!mapUpdateSubscribers.containsKey(txn.Subscriber__c)){
				mapUpdateSubscribers.put(txn.Subscriber__c, new Account( Id = txn.Subscriber__c, Subscriber_Digital_Status__c = 'Inactive'));
				System.debug('### Failed MPP Transaction: ' + txn.Subscriber__c);
			}
		}
	}

	/** Process the successful transactions for digital accounts
	*/
	private void processDigitalSuccesses(Set<MPP_Transaction_History__c> transactions, Map<Id, Account> mapUpdateSubscribers){
		for(MPP_Transaction_History__c txn : transactions){
			mapUpdateSubscribers.put(txn.Subscriber__c, new Account( Id = txn.Subscriber__c, Subscriber_Digital_Status__c = 'Active' ));
			System.debug('### Success MPP Transaction: ' + txn.Subscriber__c);
		}
	}
	
	/** Process the failed transactions for premium accounts
	*/
	private void processPremiumFailures(Set<MPP_Transaction_History__c> transactions, List<Subscription__c> updateSubscriptions){
		Set<Id> subs = new Set<id>();	
		for(MPP_Transaction_History__c txn : transactions){
			subs.add(txn.Subscription__c);
		}
		
		List<Voucher_Adjustment__c> vouchers = [SELECT Id, Subscription__c, End_Date__c FROM Voucher_Adjustment__c WHERE Subscription__c IN :subs ORDER BY End_Date__c];
		Map<Id, Date> endDates = new Map<Id, Date>();
		for(Voucher_Adjustment__c voucher : vouchers){
			if(endDates.keySet().contains(voucher.Subscription__c) && voucher.End_Date__c > endDates.get(voucher.Subscription__c)){
				endDates.remove(voucher.Subscription__c);
			}
			
			endDates.put(voucher.Subscription__c, voucher.End_Date__c);
		}

		for(MPP_Transaction_History__c txn : transactions){
			updateSubscriptions.add(new Subscription__c( Id = txn.Subscription__c, 
														 payment_details_received__c = true, 
														 Subscription_Status__c = 'Pending Cancellation',
														 Cancellation_Date__c = (endDates.keySet().contains(txn.Subscription__c) ? endDates.get(txn.Subscription__c) : txn.Subscription_Start_Date__c/*date.today()*/)));

		}
	}
	
	/** Process the successful transactions for premium accounts
	*/
	private void processPremiumSuccesses(Set<MPP_Transaction_History__c> transactions, List<Subscription__c> updateSubscriptionsNoLock, List<Subscription__c> updateSubscriptionsWithLock){

		Set<Id> subscriptionIdsToUpdate = new Set<Id>();
		// Successful transaction for premium subscriber
		for(MPP_Transaction_History__c txn : transactions){
			subscriptionIdsToUpdate.add(txn.Subscription__c);
		}
		
		//PP-1631
		// Subscriptions that are in Offered move to Pending
		List<Subscription__c> offeredSubs = [SELECT Id, Subscription_Status__c, payment_details_received__c,Is_One_Off_Payment__c FROM Subscription__c WHERE Id IN :subscriptionIdsToUpdate AND Subscription_Status__c = 'Offered'];
		for(Subscription__c sub : offeredSubs){
			
			System.debug('processPremiumSuccesses one of payment status is '+sub.Is_One_Off_Payment__c);
			if (sub.Is_One_Off_Payment__c != true){ 
				sub.Subscription_Status__c = 'Pending';
			}
			updateSubscriptionsNoLock.add(sub);
		}
				
		// Subscriptions that in pending cancellation, can go to Active, InRenewal (no Trigger) or InRenewal (with Trigger)
		List<Subscription__c> pendingCancellationSubs = [SELECT Id, Subscription_Status__c, payment_details_received__c, End_Date__c, IF_11_Week_Renewal_Update_Date_Hidden__c, IF_DD_D03_Extraction_Date__c, Is_One_Off_Payment__c FROM Subscription__c WHERE Id IN :subscriptionIdsToUpdate AND Subscription_Status__c = 'Pending Cancellation'];
		List<Subscription__c> newSubs = [SELECT Id, Previous_Subscription__c FROM Subscription__c WHERE Previous_Subscription__c IN :subscriptionIdsToUpdate];

		// Create a set of subs that have had new subs created by renewal
		Set<Id> renewed = new Set<Id>();
		for(Subscription__c sub : newSubs){
			renewed.add(sub.Previous_Subscription__c);
		}

		for(Subscription__c sub : pendingCancellationSubs){

			//RW310712 to resolve pending cancellation issue
			System.debug('processPremiumSuccesses one of payment status is '+sub.Is_One_Off_Payment__c);
			if (sub.Is_One_Off_Payment__c == true){ 
				sub.Subscription_Status__c = 'Pending Cancellation';
			}
			
			if(sub.Is_One_Off_Payment__c != true){
			Date renewalDate = (sub.IF_DD_D03_Extraction_Date__c != null) ? sub.IF_DD_D03_Extraction_Date__c :  sub.IF_11_Week_Renewal_Update_Date_Hidden__c;
			if(sub.Is_One_Off_Payment__c != true && Date.today() < renewalDate){
				// The subscription hasn't reached renewal so set back to active
				sub.Subscription_Status__c = 'Active';
				updateSubscriptionsNoLock.add(sub);
			} else{
				// The In Renewal date has past, so set the state to In Renewal
				sub.Subscription_Status__c = 'In Renewal';
				
				// Has a new sub already been created for this renewal?
				// If it has disable the trigger with the 'lock'
				// Otherwise we want the trigger to fire
				if(renewed.contains(sub.Id)){
					updateSubscriptionsNoLock.add(sub);
				} else{
					updateSubscriptionsWithLock.add(sub);					
				}
			}
		}
	}
}	


}