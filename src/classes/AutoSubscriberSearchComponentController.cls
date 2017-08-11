/*
 * File Name   : AutoSubscriberSearchComponentController
 * Description : Controller for Visualforce Page AutoSubscriberSearchComponent 
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 */ 
global with sharing class AutoSubscriberSearchComponentController {
	
	/**
	 * Remote Method that's called from javascript remoting and searches subscribers byt their TSNumbers
	 * given a search term.
	 * 
	 * @param searchTopic Search term for the SOQL query.
	 */
	@RemoteAction
	global static List<Account> doAutoCompleteSearch(String searchTopic){
		List<Account> resultAccounts = new List<Account>();
		searchTopic = searchTopic.trim();
		if(searchTopic != null && searchTopic.length() >= 4) {
			// Trim the searchtopic
			string tempWhere = '%' + searchTopic.replace(' ', '%') + '%';
			string tempFind = '*' + searchTopic.replace(' ', '*') + '*';
			//Do the search.
			resultAccounts = [FIND :tempFind
								IN all Fields
								RETURNING account 
									(Id, Name, Subscriber_Number_static__c, PersonMailingPostalCode, RecordType.Name, PersonEmail, PersonHomePhone, TMG_Model_Score_Img__c 
								where 
									(RecordType.Name = :Constants.RECTYPE_INDIVSUB
									or RecordType.Name = :Constants.RECTYPE_DIGISUB)
									and
									(Subscriber_Number_static__c like :tempWhere 
									or name like :tempWhere 
									or PersonMailingPostalCode like :tempWhere
									or GUID__c like :tempWhere
									or PersonEmail like :tempWhere)
								order by TMG_Model_Score__c desc) 
								limit 20][0];
		}
		if (resultAccounts == null || resultAccounts.isEmpty())
			return null;
		return resultAccounts;
	}
}