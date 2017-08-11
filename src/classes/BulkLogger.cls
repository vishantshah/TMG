/**
* @author Wiktor Czykin
* @date 16/12/2015
* @description Interface to be implemented by webservice helper methods to support logging for chained requests
#############Change Log#############
Modified by     Version     Change Date
**/
public interface BulkLogger{
	void addLogToBuffer(Webservice_Log__c log);
	void saveLogBuffer(); 
}