/**
* @author Unknown
* @date Unknown
* @description Task trigger handler
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         06/01/2016  //added singleton pattern
Vishant Shah	1.2			12/10/2016	//splitted out query from setWeeklyPriceToSubs so we only do 1 query to get Subs
										//and added new method setProductName
**/
public with sharing class TaskTriggerHandler {
 	
 	private static TaskTriggerHandler instance;
 	private Map<Id, Subscription__c> subsMap;
 	private Map<Id, Zuora__Subscription__c> digitalSubsMap;

	public static TaskTriggerHandler getInstance() {
        if (instance == null) instance = new TaskTriggerHandler();
        return instance; 
    }
	
	public void BeforeInsert(List<Task> newTasks) {
		getTaskSubscriptions(newTasks);
		setWeeklyPriceToSubs(newTasks);
		setProductName(newTasks, null);
	}
	
	public void BeforeUpdate(List<Task> newTasks, Map<Id, Task> oldMap) {
		getTaskSubscriptions(newTasks);
		setWeeklyPriceToSubs(newTasks);
		setProductName(newTasks, oldMap);
	}

	/*************************************************************************************** 
    Developer - Vishant Shah
    Date - 12/10/2016
    Version - 1.2
    Function - Methon to extract Subscriptions from Tasks, so we dont have to do multiple queries for Subs
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private void getTaskSubscriptions(List<Task> newTasks){
		
		Set<Id> subIds 		  = new Set<Id>();
		Set<Id> digitalSubIds = new Set<Id>();

		subsMap = new Map<Id, Subscription__c>();
		digitalSubsMap = new Map<Id, Zuora__Subscription__c>();

		for (Task newTask : newTasks) {
			if (newTask.WhatId != null) {
				if (newTask.WhatId.getSobjectType() == Subscription__c.Sobjecttype) {
					subIds.add(newTask.WhatId);
				}

				if (newTask.WhatId.getSobjectType() == Zuora__Subscription__c.Sobjecttype){
					digitalSubIds.add(newTask.WhatId);
				}
			}
		}

		if (!subIds.isEmpty()) {
			subsMap = new Map<Id, Subscription__c>([SELECT Weekly_Price__c, Subscriber__r.PersonContactId, Product__c, Product__r.Name 
													  FROM Subscription__c 
													 WHERE Id IN :subIds]);
		}

		if (!digitalSubIds.isEmpty()){
			digitalSubsMap = new Map<Id, Zuora__Subscription__c>([SELECT Subscription_Product__c FROM Zuora__Subscription__c WHERE Id IN :digitalSubIds]);
		}
	}


	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Updates weekly price on task and related who Id based on WhatId if WhatId is of Subscription__c type
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private void setWeeklyPriceToSubs(List<Task> newTasks) {
		for (Task newTask : newTasks) {
			if (newTask.WhatId != null && subsMap.containsKey(newTask.WhatId)) {
				Subscription__c sub = subsMap.get(newTask.WhatId);
				newTask.Sub_Weekly_Price__c = sub.Weekly_Price__c;
				if (newTask.WhoId == null) {
					newTask.WhoId = sub.Subscriber__r.PersonContactId;
				}
			}
		}
	}

	/*************************************************************************************** 
    Developer - Vishant Shah
    Date - 12/10/2016
    Version - 1.2
    Function - Update Task.Product__c with Subscription.Product__r.Name JIRA 5127
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private void setProductName(List<Task> newTasks, Map<Id, Task> oldMap) {
		for (Task newTask : newTasks) {

			if (newTask.WhatId != null){

				String productName;

				//if the task Status is not OUTCOME SALE, Set Product__c to null
				newTask.Product__c = null;

				if(subsMap.containsKey(newTask.WhatId)){
					Subscription__c sub = subsMap.get(newTask.WhatId);
					productName = sub.Product__c == null ? '' : sub.Product__r.Name;
				}

				if(digitalSubsMap.containsKey(newTask.WhatId)){
					Zuora__Subscription__c sub = digitalSubsMap.get(newTask.WhatId);
					productName = sub.Subscription_Product__c == null ? '' : sub.Subscription_Product__c;
				}

				if (String.isNotBlank(productName)){
					
					Boolean changedOrNewTask = true;	//defaulting to true to handle before Insert.
					
					if (oldMap != null) {
						Task oldTask = oldMap.get(newTask.Id);
						if (oldTask.WhatId == newTask.WhatId &&
								oldTask.Status == newTask.Status &&
								oldTask.Outcome__c == newTask.Outcome__c &&
								oldTask.Product__c == productName){
							changedOrNewTask = false;
							//if there are no changes to task status and outcome reset the product__c, as we set it to null above.
							newTask.Product__c = oldTask.Product__c;
						}
					}

					//if it is a new or changed which is COMPLETED SALE , set the new product name
					if (changedOrNewTask &&
							newTask.Status == Constants.TSTATUS_COMPLETED && 
							newTask.Outcome__c == Constants.TOUTCOME_SALE) {
						newTask.Product__c = productName;
					}  
				}  
			}  
		}
	} 

}