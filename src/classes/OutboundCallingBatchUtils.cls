/**
* Author:       Michal Szewczyk
* Date:
* Description:  Helper methods for Outbound Calling Batches
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Szewczyk   10/10/2016  - changed getQueueId
* Vishant Shah      05/05/2017  - added createCaseRecord()
**/

public with sharing class OutboundCallingBatchUtils {

   private static Map<String,Id> queueMapping = new Map<String,Id>();  

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 7/07/2016
    Version - 1.0
    Function -  Populate case fields based on json string input
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static Case populateCaseValues(String jsonInput){
		  Case deserializedCase = (Case) JSON.deserialize(jsonInput, Case.class);
		  return deserializedCase;
	}

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 7/07/2016
    Version - 1.0
    Function - Fetch confing records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static Outbound_Call_Batch_Setting__c fetchConfigRecord(String batchName){

		Outbound_Call_Batch_Setting__c configRecord;
		List<Outbound_Call_Batch_Setting__c> tmpRec = [	SELECT 	Id,
																Batch_Class_Name__c,
																Batch_Job_Notifications__c,
																Batch_Status__c,
																Cron_String__c,
																Executions__c,
																Last_Execution_Error__c,
																Job_Id__c,
																Outbound_Call_Setting__c,
																Outbound_Call_Setting__r.Default_Queue_Name__c,
																Parameters__c,
																Scope__c,
																Active__c
					 									FROM Outbound_Call_Batch_Setting__c
						 								WHERE Batch_Class_Name__c =:batchName AND Active__c = true];

		if(tmpRec.size() == 1){
			configRecord = tmpRec[0];
			return configRecord;
		} else if(tmpRec.size() > 1) {
			throw new TelegraphApplicationException('Active Outbound Calling Batch has more than one active config record');
		} else {
			throw new TelegraphApplicationException('Active Outbound Calling Batch config record was not found');
		}
	}

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 7/07/2016
    Version - 1.0
    Function -
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         10/10/2016  - changed to more static
    ****************************************************************************************/
    public static Id getQueueId (String queueName) {    

        if(queueMapping.size() == 0 ) {
            for(Group tmpGroup : [Select Id, Name, DeveloperName, Type from Group where Type = 'Queue']) {
                queueMapping.put(tmpGroup.Name,tmpGroup.Id);
            }
        }

    	if(queueMapping.size() > 0 && queueMapping.containsKey(queueName)) {
    		return queueMapping.get(queueName);
    	} else {
			throw new TelegraphApplicationException('The queue does not exist : ' + queueName);
    	}
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 05/05/2017
    Version - 1.0
    Function - to create a reusable CASE creation method
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public static Case createCaseRecord(Case templateCase, Subscription__c sub, Id recordTypeId, Id  ownerId){
        Case newCase                     = templateCase.clone();
        newCase.OwnerId                  = ownerId;
        newCase.AccountId                = sub.Subscriber__c;
        newCase.Print_Subscription__c    = sub.Id;
        newCase.RecordTypeId             = recordTypeId;
        newCase.OC_Batch_Updated_Date__c = Date.today();
        return newCase;
    }

}
