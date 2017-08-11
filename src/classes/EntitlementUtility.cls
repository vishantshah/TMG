/**
* @author Michal Szewczyk
* @date 15/01/2016
* @description Entitelments fetching helper class
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk 1.1         19/04/2016  //modified isNewEntitlementsActive() - return value o
Michal Szewczyk	1.2			28/04/2016	//start using Entitlement__c instead of Name for entitlement name 
**/

public class EntitlementUtility {
	

	public static Map<String,Set<String>> mapProductNameWithEntitlements;
	public static Map<Id,Set<String>> mapProductIdWithEntitlements;

	
	static {
		 mapProductNameWithEntitlements = new Map<String, Set<String>>();
		 mapProductIdWithEntitlements = new Map<Id, Set<String>>();
		//fetch ZProductFeature junction object to build product ->> feature map
	 	for(zqu__ZProductFeature__c featureJunction :[SELECT zqu__ZFeature__c, zqu__ZProduct__c,zqu__ZProduct__r.Name,zqu__ZFeature__r.Entitlement__c FROM zqu__ZProductFeature__c]){
		 	 if(!mapProductIdWithEntitlements.containsKey(featureJunction.zqu__ZProduct__c)) {
		 	 		Set<String> newSet = new Set<String>();
		 	 		newSet.add(featureJunction.zqu__ZFeature__r.Entitlement__c);
		 	 		mapProductNameWithEntitlements.put(featureJunction.zqu__ZProduct__r.Name,newSet);
		 	 		mapProductIdWithEntitlements.put(featureJunction.zqu__ZProduct__c,newSet);
		 	 } else {
		 	 		Set<String> existSet = mapProductNameWithEntitlements.get(featureJunction.zqu__ZProduct__r.Name);
		 	 		existSet.add(featureJunction.zqu__ZFeature__r.Entitlement__c);
		 	 		mapProductNameWithEntitlements.put(featureJunction.zqu__ZProduct__r.Name,existSet);
		 	 		mapProductIdWithEntitlements.put(featureJunction.zqu__ZProduct__c,existSet);
		 	 }
	 	}
	} 

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/01/2016
    Version - 1.0
    Function - Fetch old product name based on Zuora Feature definition
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static String getOldEntitlementName(String featureName) {
	 	Entitlements_Mapping__c instanceCustom = Entitlements_Mapping__c.getInstance(featureName);
	 	if(instanceCustom != null) {
	 		return Entitlements_Mapping__c.getInstance(featureName).Old_Name__c;
	 	} 

	 	return '';
	}

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/01/2016
    Version - 1.0
    Function - Check that new Zuora entitlments are on
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         19/04/2016		- changed return value 
    ****************************************************************************************/
	public static Boolean isNewEntitlementsActive(){
	 	return (Entitlements_Mapping__c.getAll().size() > 0 ? false : true );
	}

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/01/2016
    Version - 1.0
    Function - Fetch old product name based on new product assignment (print)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
 	public static String getPrintFeatureAsProductName(Id productId){
	 	String printFeatureName = '';
 		for(String tmp : mapProductIdWithEntitlements.get(productId)){
	 		if(Entitlements_Mapping__c.getInstance(tmp) != null && Entitlements_Mapping__c.getInstance(tmp).Is_print__c) {
	 			printFeatureName = tmp;
	 			break;
	 		}
 		}
 		return EntitlementUtility.getOldEntitlementName(printFeatureName);
	 }

 	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/01/2016
    Version - 1.0
    Function - Fetch old product name based on new product assignment (digital)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
 	public static String getDigitFeatureAsProductName(Id productId){
	 	String digitFeatureName = '';
 		for(String tmp : mapProductIdWithEntitlements.get(productId)){
	 		if(Entitlements_Mapping__c.getInstance(tmp) != null && !Entitlements_Mapping__c.getInstance(tmp).Is_print__c) {
	 			digitFeatureName = tmp;
	 			break;
	 		}
 		}
 		return EntitlementUtility.getOldEntitlementName(digitFeatureName);
	 }
}