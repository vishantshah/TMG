public without sharing class UsageTrackingTriggerHandler {
	
	public static void beforeInsertHandler(list<Usage_Tracking__c> newUsage){
		firstAccessDateIsNotNull(newUsage);
	}
	
	public static void afterInsertHandler(list<Usage_Tracking__c> newUsage){
		updateAccountAccessedDates(newUsage, null);
	}
	
	public static void beforeUpdateHandler(list<Usage_Tracking__c> newUsage, map<id, Usage_Tracking__c> oldUsage){
		
		firstAccessDateDontGoForwardInTime(newUsage, oldUsage);
		lastAccessDateDontGoBackInTime(newUsage, oldUsage);
		
	}
	
	public static void afterUpdateHandler(list<Usage_Tracking__c> newUsage, map<id, Usage_Tracking__c> oldUsage){
		updateAccountAccessedDates(newUsage, oldUsage);
	}
	
	private static void updateAccountAccessedDates(list<Usage_Tracking__c> newUsage, map<id, Usage_Tracking__c> oldUsage){
		
		map<id, Account> updatedAccounts = new map<id, Account>();
		set<Id> accountId = new set<Id>();
		
		for(Usage_Tracking__c newUse : newUsage){
			
			string deviceType = newUse.Device_Type__c;
			if((deviceType == 'Tablet' || deviceType == 'Mobile') && newUse.Account__c != null){
			
				//Has there been a change in the access information (typically yes - don't see what else there is to change)
				if(oldUsage == null){//Insert
					accountId.Add(newUse.Account__c);
				}
				else{//Update
					Usage_Tracking__c oldUse = oldUsage.get(newUse.Id);
					
					if(oldUse.First_Accessed_Date__c != newUse.First_Accessed_Date__c || oldUse.Last_Accessed_Date__c != newUse.Last_Accessed_Date__c){
						accountId.Add(newUse.Account__c);
					}
				}
				
			}
			
		}
		system.debug('***accountId: ' + accountId);
		
		if(!accountId.isEmpty()){
			
			//Get the affected accounts
			map<Id, Account> accounts = new map<Id, Account>([select id, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c from Account where id in :accountId]);
			system.debug('***accounts1: ' + accounts);
			
			//Loop back around again and update accounts
			for(Usage_Tracking__c newUse : newUsage){
				
				if(accounts.keySet().contains(newUse.Account__c)){
					
					Account a = accounts.get(newUse.Account__c);
					system.debug('***a: ' + a);
					
					if(newUse.Device_Type__c == 'Tablet'){
						a.Tablet_First_Accessed__c = populateFirstAccessDate(a.Tablet_First_Accessed__c, newUse.First_Accessed_Date__c, newUse.Last_Accessed_Date__c);
						
						a.Tablet_Last_Accessed__c = populateLastAccessDate(a.Tablet_Last_Accessed__c, newUse.Last_Accessed_Date__c);
					}
					else{
						a.Mobile_First_Accessed__c = populateFirstAccessDate(a.Mobile_First_Accessed__c, newUse.First_Accessed_Date__c, newUse.Last_Accessed_Date__c);
						
						a.Mobile_Last_Accessed__c = populateLastAccessDate(a.Mobile_Last_Accessed__c, newUse.Last_Accessed_Date__c);
					}
					
					accounts.put(a.Id, a);
				}
				
			}
			system.debug('***accounts2: ' + accounts);
			
			update accounts.values();
		}
		
	}
	
	private static dateTime populateFirstAccessDate(dateTime oldFirstAccess, dateTime newFirstAccess, dateTime newLastAccess){
		dateTime firstAccessDate;
		
		if(oldFirstAccess == null && newFirstAccess == null){
			firstAccessDate = newLastAccess;
		}
		else if (oldFirstAccess == null || oldFirstAccess > newFirstAccess){
			firstAccessDate = newFirstAccess;
		}
		else{
			//If all else fails,  just return the original value
			firstAccessDate = oldFirstAccess;
		}
		
		return firstAccessDate;
	}
	
	private static dateTime populateLastAccessDate(dateTime oldLastAccess, dateTime newLastAccess){
		dateTime lastAccessDate;
		
		if(oldLastAccess == null){
			lastAccessDate = newLastAccess;
		}
		else if (oldLastAccess < newLastAccess){
			lastAccessDate = newLastAccess;
		}
		else{
			//If all else fails,  just return the original value
			lastAccessDate = oldLastAccess;
		}
		
		return lastAccessDate;
	}
	
	private static void lastAccessDateDontGoBackInTime(list<Usage_Tracking__c> newUsage, map<id, Usage_Tracking__c> oldUsage){
		
		for(Usage_Tracking__c newTracker : newUsage){
			Usage_Tracking__c oldTracker = oldUsage.get(newTracker.Id);
			
			//Seems unlikely,  but,  don't go back in time!
			if(newTracker.Last_Accessed_Date__c < oldTracker.Last_Accessed_Date__c){
				newTracker.Last_Accessed_Date__c = oldTracker.Last_Accessed_Date__c;
			}
		}
		
	}
	
	private static void firstAccessDateDontGoForwardInTime(list<Usage_Tracking__c> newUsage, map<id, Usage_Tracking__c> oldUsage){
		
		for(Usage_Tracking__c newTracker : newUsage){
			Usage_Tracking__c oldTracker = oldUsage.get(newTracker.Id);
			
			//Seems unlikely,  but,  don't go forward in time!
			if(newTracker.First_Accessed_Date__c > oldTracker.First_Accessed_Date__c){
				newTracker.First_Accessed_Date__c = oldTracker.First_Accessed_Date__c;
			}
		}
		
	}
	
	private static void firstAccessDateIsNotNull(list<Usage_Tracking__c> newUsage){
		
		for(Usage_Tracking__c newTracker : newUsage){
			
			if(newTracker.First_Accessed_Date__c == null){
				newTracker.First_Accessed_Date__c = newTracker.Last_Accessed_Date__c;
			}
		}
		
	}
	
}