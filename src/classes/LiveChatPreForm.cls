/**
* Author:       Pawel Chrzanowski
* Date:         17/03/2017
* Description:  Controller for LiveChatPreForm page
* ******************* Change Log *******************
**/
public class LiveChatPreForm {

    public String caseRT {get; private set;}
    public String salesButtonId {get; private set;}
    public String serviceButtonId {get; private set;}
    
    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        17/03/2017
    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public LiveChatPreForm(){
        try{
            caseRT = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_DIGITALSERVICES, Case.class.getName());
            salesButtonId = String.valueOf([SELECT Id FROM LiveChatButton WHERE DeveloperName = 'Chat_with_TMG_Sales'][0].Id).left(15);
            serviceButtonId = String.valueOf([SELECT Id FROM LiveChatButton WHERE DeveloperName = 'Chat_with_TMG_Service'][0].Id).left(15);
        }catch(Exception e){
            System.debug('Error in LiveChatPreForm: ' + e.getMessage());
        }
    }
}