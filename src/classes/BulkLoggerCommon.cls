/**
* @author Wiktor Czykin
* @date 16/12/2015
* @description Default implementation of BulkLogger
#############Change Log#############
Modified by     Version     Change Date
**/
public abstract class BulkLoggerCommon implements BulkLogger{

	@TestVisible protected String sLoggerKey;
	@TestVisible private static Boolean bTestFailure = false;
	public Boolean bUseBulkLogging = false;
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/12/2015
    Version - 1.0
    Function - default constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public BulkLoggerCommon(){}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/12/2015
    Version - 1.0
    Function - Constructor - sets the key identifier for the log
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public BulkLoggerCommon(String sLoggerKey){
		this.sLoggerKey = sLoggerKey;
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/12/2015
    Version - 1.0
    Function - adds log to buffer map with simple validation checks
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public void addLogToBuffer(Webservice_Log__c log){
		if(String.isBlank(this.sLoggerKey)) throw new TelegraphApplicationException('Incorrect usage of bulk logger.');
		if(!TMGUtil.mapCommonLogBuffer.containsKey(this.sLoggerKey)){
			TMGUtil.mapCommonLogBuffer.put(this.sLoggerKey, new List<Webservice_Log__c>());
		}
		TMGUtil.mapCommonLogBuffer.get(this.sLoggerKey).add(log);
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/12/2015
    Version - 1.0
    Function - saves respective list of webservice logs
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public void saveLogBuffer(){
		if(String.isNotBlank(this.sLoggerKey) && TMGUtil.mapCommonLogBuffer.containsKey(this.sLoggerKey) && !TMGUtil.mapCommonLogBuffer.get(this.sLoggerKey).isEmpty()){
			try{
				if(Test.isRunningTest() && bTestFailure){
					TMGUtil.mapCommonLogBuffer.get(this.sLoggerKey)[0].ProfileId__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin magna risus, consequat sit amet nibh ut, auctor faucibus ex. Mauris sed aliquam orci. Nulla sit amet purus justo. Mauris justo nunc, commodo at bibendum et, fermentum sit amet velit. Nunc metus.';
				}
				insert TMGUtil.mapCommonLogBuffer.get(this.sLoggerKey);	
			}catch(Exception e){
				System.debug('fail silently on webservice log insert');
			}
		}
	} 
}