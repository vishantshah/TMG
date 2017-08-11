/**
* @author Pawel Chrzanowski
* @date 09/09/2016
* @description 
#############Change Log#############
Modified by     	Version     Change Date
**/
@isTest
private class OutboundCallRuleTriggerHandlerTest {

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 09/09/2016
    Function - method to test  onBeforeDelete
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    @isTest static void onBeforeDeleteTest(){
		TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallRule();

        try{
            delete tdu.lstOutboundCallRule;
        }catch(Exception e){
            System.assert(e.getMessage().contains(Label.OC_Delete_Active_Rule_Error));
        }
    }

}