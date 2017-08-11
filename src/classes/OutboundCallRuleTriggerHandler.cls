/**
* @author Pawel Chrzanowski
* @date 09/09/2016
* @description Handler class for Outbound Call Rule trigger
#############Change Log#############
Modified by     Version     Change Date
**/
public class OutboundCallRuleTriggerHandler {

    private static OutboundCallRuleTriggerHandler instance;

    public static OutboundCallRuleTriggerHandler getInstance(){
        if(instance == null) instance = new OutboundCallRuleTriggerHandler();
        return instance; 
    }

    public void onBeforeDelete(List<Outbound_Call_Rule__c> ocRules, Map<Id, Outbound_Call_Rule__c> ocRulesMap){
        for(Outbound_Call_Rule__c ocr : ocRules){
            if(ocr.Active__c) ocr.addError(Label.OC_Delete_Active_Rule_Error);
        }
    }

}