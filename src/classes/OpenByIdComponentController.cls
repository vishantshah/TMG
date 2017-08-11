/*
 * File Name   : OpenByIdComponentController
 * Description : Controller for Visualforce Page OpenByIdComponent 
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 * 1.1 27/05/2015 Wiktor Czykin	 Modified doOpenById()
 */ 
global with sharing class OpenByIdComponentController {
	
/**
	 * Remote Method that's called from javascript remoting and searches subscribers byt their TSNumbers
	 * given a search term.
	 * @param searchTopic Search term for the SOQL query.
	* 
	* Modification Log
	* ======================================================== 
	* Ver Date       Author         Modification
	* --- ---------- -------------- --------------------------
	* 1.1 27/05/2015 Wiktor Czykin 	added separate if for Account as was failing beacause there are 3 fields that return true (for Person Account) for isNameField() check 
	*								and after Summer15 looping order no longer hits valid value (was hitting First Name instead of Name)
	* 
	 */
	@RemoteAction
	global static resultWrapper doOpenById(String searchTopic){
		List<sObject> resultObjects = new List<sObject>();
		String nameField = 'Name';
		Boolean isCase = false;
		if(searchTopic != null) {
			// Trim the searchtopic
			try {
				searchTopic = searchTopic.trim();
				Id searchTopicId = Id.valueOf(searchTopic);
				Schema.SObjectType token = searchTopicId.getSObjectType();
				Schema.DescribeSObjectResult dr = token.getDescribe();
				String objectName = dr.getName();
				if (token == Case.getSobjectType()){
					nameField = 'CaseNumber, AccountId, Account.Name';
					isCase = true;
				}else if(token == Account.getSObjectType()){
					nameField = 'Name';
				}else{
					for (Schema.SObjectField drField : dr.fields.getMap().values()) {
						Schema.DescribeFieldResult fieldDescribe = drField.getDescribe() ;
						if (fieldDescribe.isNameField()){
							nameField = fieldDescribe.getName();
					}
				}
				}
				
				String queryString = 'SELECT Id, ' + nameField + ' FROM ' + objectName + 
									 ' where Id = \'' + searchTopicId + '\''; 
				//Do the search.
				resultObjects = Database.query(queryString);
			}catch (Exception ex) {
				resultObjects = null;
			}
		}
		if (resultObjects == null || resultObjects.isEmpty() || resultObjects.size() > 1)
			return null;
		
		if (isCase) {
			resultWrapper resWrap = new resultWrapper();
			Case tempCase = (Case) resultObjects[0];
			resWrap.resultId = tempCase.Id;
			resWrap.resultName = tempCase.CaseNumber;
			resWrap.accountId = tempCase.AccountId;
			resWrap.accountName = tempCase.Account.Name;
			return resWrap;
		}
		
		return new resultWrapper((Id)resultObjects[0].get('Id'), (String) resultObjects[0].get(nameField));
	}

	global class resultWrapper {
		global Id resultId {get;set;}
		global String resultName {get;set;}
		global Id accountId {get;set;}
		global String accountName {get;set;}

		global resultWrapper(Id resultIdIn, String resultNameIn) {
			resultId = resultIdIn;
			resultName = resultNameIn;
		}
		
		global resultWrapper() {}
	}
}