/**
Name: SubscriptionStatusSchedulable
* @author Wiktor Czykin 
* @date 31/03/2015
* @description 	Schedulable class to trigger off Queueable class -> cannot implement Schedulable and Queueable in one class :/
##########Change Log##########
Modified by     Version     Change Date 
Wiktor Czykin	1.1 		13/04/2015 //modified so that parameters for SubscriptionStatusQueueable call could be specified as well (new go method added)
*/
public without sharing class SubscriptionStatusSchedulable implements Schedulable {

	public static final String CRON = '0 10 0 * * ? *'; 
	public static final String JOBNAME = 'SubscriptionStatusUpdate';
	public Integer iRecordsProcessedInInstance{get;set;}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created -  13/04/2015
	Version - 1.0 
	Function - 	static method to schedule queueable with parameter specifying count of records processed in one queueable execution
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public static void go(Integer iRecordsProcessedInInstance){
		SubscriptionStatusSchedulable sss = new SubscriptionStatusSchedulable();
		sss.iRecordsProcessedInInstance = iRecordsProcessedInInstance;
	    String sJobName = JOBNAME;
	    if(sss.iRecordsProcessedInInstance != null){
	    	sJobName += '_'+sss.iRecordsProcessedInInstance;
	    }
	    if(Test.isRunningTest()){
	    	sJobName ='Test'+sJobName;
	    }
    	System.schedule(sJobName, CRON, sss);
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created -  31/03/2015
	Version - 1.0 
	Function - 	static method to schedule queueable with default parameters 
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public static void go(){
	    SubscriptionStatusSchedulable sss = new SubscriptionStatusSchedulable();
	    String sJobName = JOBNAME;
	    if(Test.isRunningTest()){
	    	sJobName ='Test'+sJobName;
	    }
    	System.schedule(sJobName, CRON, sss);
  	}
  
	public void execute(SchedulableContext ctx){
    	System.enqueueJob(new SubscriptionStatusQueueable(this.iRecordsProcessedInInstance, null));
  	} 
}