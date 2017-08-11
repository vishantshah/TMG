/**
* @author Wiktor Czykin(Tquila)
* @date 11/02/2015
* @description Test class for RecordTypeUtility class 
#############Change Log#############
Modified by     Version     Change Date
W
**/
@isTest
private class RecordTypeUtilityTest {

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 11/02/2015
    Version - 1.0
    Function - Test all flows of RecordTypeUtility - fetching of id based on RT name, fetching of name of RT based on Id
    #############Change Log#############
	Modified by     Version     Change Date
	Cristina A      1.1         19/11/2015 //remove businessAccount recordType
    ****************************************************************************************/
	private static testMethod void testAll(){
		Map<Id, String> mapRecordTypeIdToName = new Map<Id, String>();
		Map<String, Id> mapRecordTypeNameToId = new Map<String, Id>();
		for(RecordType rt : [select Id, Name from RecordType where SobjectType='Account']){
			mapRecordTypeIdToName.put(rt.Id, rt.Name);
			mapRecordTypeNameToId.put(rt.Name, rt.Id);
		}
		Test.startTest();
			Id nonExistingRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, 'bla bla', 'Account'); 
			String sNonExistingRecordTypeName = RecordTypeUtility.getRecordTypeName(Case.SObjectType, mapRecordTypeNameToId.get(Constants.RECTYPE_ACCOUNT_BUSINESSACCOUNT), 'Case'); 
			Map<String, Schema.RecordTypeInfo> mapx = RecordTypeUtility.getRecordTypeInfoMapForObject(Case.SObjectType, Case.class.getName());
		Test.stopTest();
		
		System.assertEquals(null, nonExistingRecordTypeId, 'Magically found something where there should be nothing.');
		System.assertEquals(null, sNonExistingRecordTypeName, 'Magically found something where there should be nothing.');
		System.assertNotEquals(null, mapx);
		
		
	}

}