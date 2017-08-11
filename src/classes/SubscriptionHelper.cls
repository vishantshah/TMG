/**************************************************************************************
* @author: Vishant Shah
* @date: 11/05/2017 
* @description: Helper class SubscriptionTriggerHandler
* Modified by     Version     Change Date
***************************************************************************************/

public virtual with sharing class SubscriptionHelper{

	/***************************************************************************************
    Developer - Vishant Shah
    Date - 11/05/2017
    Version - 1.0
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static void autoCloseCases(Map<Id, Subscription__c> mapOldSubs, Map<Id, Subscription__c> mapNewSubs){
		OCCaseAutoclose__c autoClose = OCCaseAutoclose__c.getInstance();
		Set<Id> changedSubIds        = new Set<Id>();
		Set<Id> changedSubStatusIds  = new Set<Id>();
		Set<Id> changedSubCancIds    = new Set<Id>();

        if(autoClose != null && autoClose.Auto_Close_Cases__c != null && autoClose.Auto_Close_Cases__c){

        	for(Id keyId : mapNewSubs.keySet()){
                if(mapNewSubs.get(keyId).Subscription_Status__c != mapOldSubs.get(keyId).Subscription_Status__c){
                    changedSubIds.add(keyId);
                    changedSubStatusIds.add(keyId);
                }
                if(mapNewSubs.get(keyId).Cancellation_Reason__c != mapOldSubs.get(keyId).Cancellation_Reason__c){
                    changedSubIds.add(keyId);
                    changedSubCancIds.add(keyId);
                }
            }

            if (changedSubIds.size() > 0){
            	List<Case> casesToUpdate         = new List<Case>();
            	List<String> caseRecordTypeNames = new List<String>{Constants.OC_SALES_RECORD_TYPE_NAME, Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Constants.OC_DDCX_CASE_RECORD_TYPE_NAME};
            	Set<String> setSubStatus       = new Set<String>{Constants.SSTATUS_ACTIVE, Constants.SSTATUS_PENDING, Constants.SSTATUS_WITHDRAWN, Constants.SSTATUS_DECLINED};

	            Map<String, List<String>> mapProjectReason = new Map<String, List<String>>(); 
	            for (Outbound_Calling_Configuration__mdt exclusionReasons : [SELECT Project__c, Reason__c FROM Outbound_Calling_Configuration__mdt]){
	            	if (!mapProjectReason.containsKey(exclusionReasons.Project__c))
	            		mapProjectReason.put(exclusionReasons.Project__c, new List<String>());

		            mapProjectReason.get(exclusionReasons.Project__c).add(exclusionReasons.Reason__c);
		        }
		        System.debug(mapProjectReason);

		        List<Case> casesToClose = [SELECT Id, RecordType.Name, Print_Subscription__c, Print_Subscription__r.Subscription_Status__c, Print_Subscription__r.Cancellation_Reason__c
		        							 FROM Case 
		        							WHERE Status != :Constants.CASE_STATUS_COMPLETED
		        							  AND Print_Subscription__c IN :changedSubIds 
		        							  AND RecordType.Name IN :caseRecordTypeNames];
		        
		        for (Case c : casesToClose){

		        	String caseRecordType        = c.RecordType.Name;
		        	String subId                 = c.Print_Subscription__c;
		        	String subStatus             = c.Print_Subscription__r.Subscription_Status__c;
		        	String subCancellationReason = c.Print_Subscription__r.Cancellation_Reason__c;

		        	if (caseRecordType == Constants.OC_SALES_RECORD_TYPE_NAME && setSubStatus.contains(subStatus) && changedSubStatusIds.contains(subId)){
		        		c.Status        = Constants.CASE_STATUS_COMPLETED;
	                    c.OC_Outcome__c = Constants.CASE_OUTCOME_AUTO_COMPLETED;
	                    casesToUpdate.add(c);
		        	} else if (changedSubCancIds.contains(subId)){

		        		for (String reason : mapProjectReason.get(caseRecordType)){
		        			if (reason == subCancellationReason){
		        				c.Status        = Constants.CASE_STATUS_COMPLETED;
	                    		c.OC_Outcome__c = Constants.CASE_OUTCOME_AUTO_COMPLETED;

		        				if (caseRecordType == Constants.OC_DD_WINBACK_RECORD_TYPE_NAME)
	                    			c.DD_Winback_Outcome__c = Constants.CASE_OUTCOME_AUTO_COMPLETED;
	                    		else 
	                    			c.DD_Cancellation_Outcome__c = Constants.CASE_OUTCOME_AUTO_COMPLETED;

	                    		casesToUpdate.add(c);
		        			}
		        		}
		        	}
		        }
		        Database.update(casesToUpdate, false);
		    }
        }
	}
}