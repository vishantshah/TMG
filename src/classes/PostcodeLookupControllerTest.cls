/* ------------------------------------------------------------------------------
   Name:        PostcodeLookupControllerTest.cls
   Description: Test PostcodeLookupController functionality  

   Date         Version Author              Summary of Changes 
   -----------  ------- -----------------   -------------------------------------
   07/09/2015   1.1     Cristina Anghenie 	Disable postcodeLookup functionality in sandboxes      
--------------------------------------------------------------------------------- */
@isTest
private class PostcodeLookupControllerTest {
	
	/*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 07/09/2015
    Version - 1.0
    Function - make sure postcode functionality doesnt run in sandboxes
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testPostcodeLooupFunctionalityEnabled() {
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadGeneral();
        Test.startTest();
        	//general settings for postcode lookup are set to false(sandbox scenario)
        	PostcodeLookupController ctrl = new PostcodeLookupController();
        	System.assertEquals(ctrl.isOn,false);
        	
        	//general settings for postcode lookup are set to true(production scenario)
        	General__c setting = General__c.getInstance(Constants.POSTCODE_LOOKUP_CUSTOMSETTINGS);
        	System.assertEquals(setting.Value_Boolean__c,false);
        	setting.Value_Boolean__c = true;
        	update setting;
        	setting = General__c.getInstance(Constants.POSTCODE_LOOKUP_CUSTOMSETTINGS);
        	System.assertEquals(setting.Value_Boolean__c,true);
        	
        	ctrl = new PostcodeLookupController();
        Test.stopTest();
        System.assertEquals(ctrl.isOn,true);
    }
}