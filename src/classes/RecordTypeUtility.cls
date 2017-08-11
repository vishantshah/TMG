/**
* @author Wiktor Czykin(Tquila)
* @date 11/02/2015
* @description Record type fetching helper class
#############Change Log#############
Modified by     Version     Change Date
**/
public class RecordTypeUtility {
	
	private static Map<String, Map<String,Schema.RecordTypeInfo>> mapRecordTypeByName = new Map<String, Map<String,Schema.RecordTypeInfo>>();
	private static Map<String, Map<Id, Schema.RecordTypeInfo>> mapRecordTypeById = new Map<String, Map<Id, Schema.RecordTypeInfo>>();
	
	
	private static void initialize(Schema.SObjectType sObjType, String sObjectAsString) {
		if (!mapRecordTypeByName.containsKey(sObjectAsString) || !mapRecordTypeById.containsKey(sObjectAsString)) {
			Schema.DescribeSObjectResult d = sObjType.getDescribe();
			mapRecordTypeByName.put(sObjectAsString, d.getRecordTypeInfosByName());
			mapRecordTypeById.put(sObjectAsString, d.getRecordTypeInfosById());
		}
	}
	
	public static ID getRecordTypeId(Schema.SObjectType sObjType, String sRecordTypeName, String sObjectAsString){
		initialize(sObjType, sObjectAsString);
		if (mapRecordTypeByName.get(sObjectAsString).containsKey(sRecordTypeName)) {
			Schema.RecordTypeInfo rtInfo = mapRecordTypeByName.get(sObjectAsString).get(sRecordTypeName);
			return rtInfo.getRecordTypeId();
		}
		return null;
	}
	
	public static String getRecordTypeName(Schema.SObjectType sObjType, Id recordTypeId, String sObjectAsString) {
		initialize(sObjType, sObjectAsString);
		if (mapRecordTypeById.get(sObjectAsString).containsKey(recordTypeId)) {
			Schema.RecordTypeInfo rtInfo =  mapRecordTypeById.get(sObjectAsString).get(recordTypeId);
			return rtInfo.getName();
		}
		
		return null;
	}

	public static Map<String, Schema.RecordTypeInfo> getRecordTypeInfoMapForObject(Schema.SObjectType sObjType, String sObjectAsString){
		initialize(sObjType, sObjectAsString);
		Map<String, Schema.RecordTypeInfo> mapToReturn = null;
		if (mapRecordTypeByName.containsKey(sObjectAsString)) {
			mapToReturn = mapRecordTypeByName.get(sObjectAsString);
		}
		return mapToReturn;
	}
}