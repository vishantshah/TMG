/************************************************************************************
Developer - Michal Szewczyk
Date - 20/01/2016
Version - 1.0
Function - test EntitlementUtility
#############Change Log#############
Modified by     	Version     Change Date
*************************************************************************************/
@isTest(SeeAllData=false)
private class EntitlementUtilityTest {
	
	/************************************************************************************
	Developer - Michal Szewczyk
	Date - 20/01/2016
    Version - 1.0
    Function - Test GetOldEntitlementName method
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         28/04/2016      //changed Name for Entitlement__c
    *************************************************************************************/
	static testMethod void testGetOldEntitlementName() {
		TestDataUtility tdu = new TestDataUtility();
        tdu.loadEntitlementsMappingSettings();
        tdu.createZProductFeatures();
        System.assertEquals('7DAY_SUBSCRIBER_', EntitlementUtility.getOldEntitlementName(tdu.lstZFeature[1].Entitlement__c));
	}

	/************************************************************************************
	Developer - Michal Szewczyk
	Date - 20/01/2016
    Version - 1.0
    Function - Test IsNewEntitlementsActive method
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
	static testMethod void testIsNewEntitlementsActive() {
		TestDataUtility tdu = new TestDataUtility();
        
		System.assertEquals(true,EntitlementUtility.isNewEntitlementsActive());
        tdu.loadEntitlementsMappingSettings();    
       	System.assertEquals(false,EntitlementUtility.isNewEntitlementsActive());

	}

	/************************************************************************************
	Developer - Michal Szewczyk
	Date - 20/01/2016
    Version - 1.0
    Function - Test GetPrintFeatureAsProductName method
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
	static testMethod void testGetPrintFeatureAsProductName() {
		TestDataUtility tdu = new TestDataUtility();
        tdu.loadEntitlementsMappingSettings();
        tdu.createZProductFeatures();

        // check when isPrint don't exist
        System.assertEquals('',EntitlementUtility.getPrintFeatureAsProductName(tdu.lstZproducts[0].id));

        // check when isPrint exist
        String nameEnt = '';
        for(String entTmp : EntitlementUtility.mapProductIdWithEntitlements.get(tdu.lstZproducts[1].id)){
				nameEnt = entTmp;
				break;
        }
        
        Entitlements_Mapping__c tmp = Entitlements_Mapping__c.getInstance(nameEnt);
        tmp.Is_print__c = true;
        update tmp;

        System.assertEquals('7DAY_SUBSCRIBER_',EntitlementUtility.getPrintFeatureAsProductName(tdu.lstZproducts[1].id));
	}

	/************************************************************************************
	Developer - Michal Szewczyk
	Date - 20/01/2016
    Version - 1.0
    Function - Test GetDigitFeatureAsProductName method
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
	static testMethod void testGetDigitFeatureAsProductName() {
		TestDataUtility tdu = new TestDataUtility();
        tdu.loadEntitlementsMappingSettings();
        tdu.createZProductFeatures();

        String nameEnt = '';
        for(String entTmp : EntitlementUtility.mapProductIdWithEntitlements.get(tdu.lstZproducts[1].id)){
				nameEnt = entTmp;
				break;
        }
        
        Entitlements_Mapping__c tmp = Entitlements_Mapping__c.getInstance(nameEnt);
        tmp.Is_print__c = false;
        update tmp;

        System.assertEquals('7DAY_SUBSCRIBER_',EntitlementUtility.getDigitFeatureAsProductName(tdu.lstZproducts[1].id));
	}
}