/**
* @author Michal Szewczyk
* @date 27/07/2016
* @description Test class for OutboundCallMenuCotroller
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class OutboundCallMenuControllerTest {
	
    /************************************************************************************
    Developer - Michal Szewczyk
    Date - 26/07/2016
    Version - 1.0
    Function - method to test the Constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void loadTest(){
         
    	List<Outbound_Call_Setting__c> menuNodes = new List<Outbound_Call_Setting__c>(); 
    		menuNodes.add(TestDataUtility.newOutboundCallSetting (Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME,Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME,''));
    		menuNodes.add(TestDataUtility.newOutboundCallSetting (Constants.OC_SALES_RECORD_TYPE_NAME,Constants.OC_SALES_VF_PAGE_NAME,''));
    	insert menuNodes;
        
        OutboundCallMenuController controller = new OutboundCallMenuController();
        System.assertEquals(menuNodes.size(),controller.menuParams.size(),'Not all menu items were fetched');        
    }
}