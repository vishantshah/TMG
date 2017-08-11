/**
* Author:       Pawel Chrzanowski
* Date:         17/03/2017
* Description:  Test for LiveChatPreForm Controller
* ******************* Change Log *******************
**/
@isTest

private class LiveChatPreFormTest {

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        17/03/2017
    Constructor test
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    static @isTest void constructorTest(){
        String caseRT = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_DIGITALSERVICES, Case.class.getName());
        String salesButtonId = String.valueOf([SELECT Id FROM LiveChatButton WHERE DeveloperName = 'Chat_with_TMG_Sales'][0].Id).substring(0,15);
        String serviceButtonId = String.valueOf([SELECT Id FROM LiveChatButton WHERE DeveloperName = 'Chat_with_TMG_Service'][0].Id).substring(0,15);
        
        LiveChatPreForm controller = new LiveChatPreForm();
        System.assertEquals(caseRT, controller.caseRT);
        System.assertEquals(salesButtonId, controller.salesButtonId);
        System.assertEquals(serviceButtonId, controller.serviceButtonId);
    }


}