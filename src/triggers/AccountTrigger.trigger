/**
* @author Unknown
* @date Unknown
* @description Account trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         30/03/2015  //reorganised
**/
trigger AccountTrigger on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    //MIrfan@Appirio 270412, introduced new custom label "ByPassAccountTriggerForProfile", to bypass trigger validations for a specific Profile.
    //This is to stop calling SAM system when bulk Account Update is done via DataLoader, for any fixes.
    //Default value should be 'None'
    System.debug('Before trigger starts => Profile Id:'+Label.ByPassAccountTriggerForProfile+'; user Profile Id:'+UserInfo.getProfileId());
    
    if(Label.ByPassAccountTriggerForProfile != UserInfo.getProfileId()){
        AccountTriggerHandler handler = AccountTriggerHandler.getInstance();

        if(Trigger.isBefore){
            if(Trigger.isInsert){
                handler.OnBeforeInsert(Trigger.new);
            } else if(Trigger.isUpdate){
                handler.OnBeforeUpdate( Trigger.old, 
                                        Trigger.new, 
                                        Trigger.newMap);
            } else if(Trigger.isDelete){
                handler.OnBeforeDelete( Trigger.old, 
                                        Trigger.oldMap);
            }
        }else if(Trigger.isAfter){
            if(Trigger.isInsert){
                handler.OnAfterInsert(Trigger.new);
            } else if(Trigger.isUpdate){
                handler.OnAfterUpdateRouter(  Trigger.old, 
                                        Trigger.new, 
                                        Trigger.oldMap, 
                                        Trigger.newMap);
            } else if(Trigger.isDelete){
                handler.OnAfterDelete(  Trigger.old,
                                        Trigger.oldMap);
            } else if(Trigger.isUnDelete){
                handler.OnUndelete(Trigger.new);    
            }
        }
    }
}