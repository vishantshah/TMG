/**
* @author Pawel Chrzanowski
* @date 07/09/2016
* @description  Outbound Calling Activator Extension
#############Change Log#############
**/
global class OutboundCallingActivator {

    public Id ocId {get;set;}
    public String errorMessage {get;set;}
    public Boolean disableButton {get;set;}
    public static final String RESULT_SUCCESS = 'success';

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        07/09/2016
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public OutboundCallingActivator(ApexPages.StandardController stdController){
        disableButton = true;

        ocId = stdController.getId();
        if(ocId == null) return;

        String ocObject;
        if(Outbound_Call_Rule__c.SObjectType == ocId.getSobjectType()){
            ocObject = 'Outbound_Call_Rule__c';
        }
        if(ocObject == null) return;

        SObject ocRecord = Database.query('SELECT Active__c FROM ' + ocObject + ' WHERE Id = :ocId');
        disableButton = (Boolean)ocRecord.get('Active__c');
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        07/09/2016
    Function    Method for JS Remoting to activate an OC config record
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @RemoteAction
    global static String activate(String id){
        Id ocId = (Id)id;
        String ocObject;

        if(Outbound_Call_Rule__c.SObjectType == ocId.getSObjectType()){
            ocObject = 'Outbound_Call_Rule__c';
        }
        if(ocObject == null) return Label.OC_Invalid_Object;

        SObject ocRecord = Database.query('SELECT Outbound_Call_Setting__c FROM ' + ocObject + ' WHERE Id = :ocId');
        Id parentId = (Id)ocRecord.get('Outbound_Call_Setting__c');
        ocRecord.put('Active__c', true);
        ocRecord.put('Status__c', parentId);

        List<SObject> lstSObjectsToUpdate = Database.query('SELECT Active__c, Status__c FROM ' + ocObject + ' WHERE Outbound_Call_Setting__c = :parentId AND Active__c = true');
        for(SObject sO : lstSObjectsToUpdate){
            sO.put('Active__c', false);
            sO.put('Status__c', null);
        }

        try{
            update lstSObjectsToUpdate;
            update ocRecord;
            return OutboundCallingActivator.RESULT_SUCCESS;
        }catch(DmlException e){
            return e.getMessage();
        }
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        07/09/2016
    Function    Method for Action Function to display Apex PageMessage
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void showErrorMessage(){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
    }
}