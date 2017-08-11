/**
* @author Unknown
* @date Unknown
* @description Action class for Cheque trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         18/06/2015  //modified Cheque_afterInsUpd_deferredCalcs();
Wiktor Czykin   1.2         30/07/2015  //moved recursion prevention flag from trigger to handler
Vishant Shah    1.3         06/10/2016  //Stopped subscription moving to Pending when Cheque is Inserted
Wiktor Czykin   1.4         01/03/2017  //modified paymentDetailsReceivedAndTotalDDPayment()
**/
public with sharing class ChequeTriggerHandler {
    
    private static ChequeTriggerHandler instance;
    public Boolean isExecuting = false;

    public static ChequeTriggerHandler getInstance(){
        if(instance == null){
            instance = new ChequeTriggerHandler();
        }
        return instance;
    }
    
    public void onBeforeInsert(List<Cheque__c> newList){
        ChequeIntoClosedBatch(newList);
    }
    public void onAfterInsert(List<Cheque__c> newList,List<Cheque__c> oldList, Map<Id,Cheque__c> newMap,Map<Id,Cheque__c> oldMap){
        if (!this.isExecuting) {
            this.isExecuting = true;

            paymentDetailsReceivedAndTotalDDPayment(newList,oldList,newMap,oldMap);
            Cheque_afterInsUpd_deferredCalcs(newList,oldList);

            this.isExecuting = false;
        }
    }
    public void onAfterUpdate(List<Cheque__c> newList,List<Cheque__c> oldList, Map<Id,Cheque__c> newMap,Map<Id,Cheque__c> oldMap){
        if (!this.isExecuting) {
            this.isExecuting = true;
            
            paymentDetailsReceivedAndTotalDDPayment(newList,oldList,newMap,oldMap);
            Cheque_afterInsUpd_deferredCalcs(newList,oldList);

            this.isExecuting = false;
        }
    }
    public void onAfterDelete(List<Cheque__c> newList,List<Cheque__c> oldList){
        if (!this.isExecuting) {
            this.isExecuting = true;
    
            Cheque_afterInsUpd_deferredCalcs(newList,oldList);

            this.isExecuting = false;
        }
    }
    public void onAfterUnDelete(List<Cheque__c> newList,List<Cheque__c> oldList){
        if (!this.isExecuting) {
            this.isExecuting = true;
            
            Cheque_afterInsUpd_deferredCalcs(newList,oldList);

            this.isExecuting = false;
        }
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Vishant Shah    1.1         06/10/2016  //Stopped subscription moving to Pending when Cheque is Inserted
    Wiktor Czykin   1.2         01/03/2017  //Restored moving to Pending for School subs only
    ****************************************************************************************/
    private void paymentDetailsReceivedAndTotalDDPayment(List<Cheque__c> newList,List<Cheque__c> oldList, Map<Id,Cheque__c> newMap,Map<Id,Cheque__c> oldMap){
        List<Id> subIds = new List<Id>();
        for (Cheque__c cs : newList) {
            if (cs.subscription__c != null) {
                subIds.add(cs.subscription__c);
            }
        }
        
        Map<Id,Subscription__c> subsIDs = new Map<Id, Subscription__c>([select Id, Subscription_Status__c, total_dd_payment__c, RecordTypeId from Subscription__c where Id in :subIds]);
        Map<Id,Subscription__c> subsMapToUpdate = new Map<Id, Subscription__c>();
        List<Subscription__c>  subs = new List<Subscription__c>();
        Id schoolRecordType = RecordTypeUtility.getRecordTypeId(Subscription__c.sObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
        for (Cheque__c chq : newList) {
            Subscription__c subscriptionRec = subsIDs.get(chq.subscription__c);
            if(subscriptionRec!=null){
                if (subsIDs.get(chq.subscription__c).Subscription_Status__c == Constants.SSTATUS_OFFERED){
                    subscriptionRec.payment_details_received__c = true;
                    subscriptionRec.payment_type__c = 'Cheque'; 
                    if(subscriptionRec.RecordTypeId == schoolRecordType){
                        subscriptionRec.Subscription_Status__c = Constants.SSTATUS_PENDING;
                    }
                }
                
                if(chq.type__c == 'Sub Payment'){
                    if (subscriptionRec.total_dd_payment__c==null) {
                        subscriptionRec.total_dd_payment__c = chq.cheque_amount__c;
                    } else {
                        if(Trigger.isInsert){
                            subscriptionRec.total_dd_payment__c = subscriptionRec.total_dd_payment__c + ((chq.cheque_amount__c!=null)?chq.cheque_amount__c:0);
                        } else {
                            /***Add New Cheque Amount and Deduct old Cheque Amount***/
                            subscriptionRec.total_dd_payment__c = subscriptionRec.total_dd_payment__c + ((chq.cheque_amount__c!=null)?chq.cheque_amount__c:0)-((oldMap.get(chq.id).cheque_amount__c!=null)?oldMap.get(chq.id).cheque_amount__c:0);
                        }
                    }
                } else if (chq.type__c == 'Refund') {
                    if (subscriptionRec.total_dd_payment__c==null) {
                        subscriptionRec.total_dd_payment__c = -chq.cheque_amount__c;
                    } else {
                        subscriptionRec.total_dd_payment__c = subscriptionRec.total_dd_payment__c - ((chq.cheque_amount__c!=null)?chq.cheque_amount__c:0);
                    }       
                }
                subsMapToUpdate.put(subscriptionRec.id,subscriptionRec);
            }
        }
        if (!subsMapToUpdate.values().isEmpty()) {
            update subsMapToUpdate.values();
        }
        
    }
    
    /*** This is for the Before Insert Method ***/
    private void ChequeIntoClosedBatch(List<Cheque__c> newList){
        
        Set<Id> batchIds = new Set<Id>();
        
        for (Cheque__c chq : newList) {
            if (chq.cheque_batch__c!=null) {
                batchIds.add(chq.cheque_batch__c);
            }
        }
        
        Map<Id, Cheque_Batch__c> batches = new Map<Id, Cheque_Batch__c>([select id, batch_closed_date__c from Cheque_Batch__c where id in :batchIds]);
        
        for (Cheque__c chq : newList) {
            if (chq.cheque_batch__c!=null) {
                Cheque_Batch__c batch = batches.get(chq.cheque_batch__c);
                if (batch.batch_closed_date__c!=null) {
                    chq.AddError('Cannot add cheque to closed batch');
                }
            }
        } 
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/06/2015  //modified the way how DeferredCalculation is called - btw this trigger method should be split into 2
    ****************************************************************************************/
    private void Cheque_afterInsUpd_deferredCalcs(List<Cheque__c> newList,List<Cheque__c> oldList){
        if (DeferredCalculation.isTestScenario == null) {DeferredCalculation.isTestScenario = false;}
        if (DeferredCalculation.inDeferredCalc == null) {DeferredCalculation.inDeferredCalc = false;}
        
        if (!DeferredCalculation.isTestScenario && !DeferredCalculation.inDeferredCalc) {
            
            DeferredCalculation.inDeferredCalc = true;
            
            DeferredCalculation.DeferredRevenueCalc calc = new DeferredCalculation.DeferredRevenueCalc();
            
            Cheque__c[] procs;
            
            if (trigger.isDelete) {
                procs = oldList;
            }
            if (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete) {
                procs = newList;
            }
            
            Set<Id> setSubIds = new Set<Id>();
            for (Cheque__c c : procs) {
                setSubIds.add(c.Subscription__c);
            }
            
            List<Subscription__c> procsubs = [select Id, Asset_Calc__c, Liab_Calc__c,total_dd_payment__c from Subscription__c where Id in :setSubIds];
            
            //MIrfan@Appirio, 210612. PP-1575: Fields incorrect on sub SUB-0005801720
            //Dedut amount on Subscription when cheque is deleted
            if (trigger.isDelete) {
                Map<Id,Subscription__c> mapSubOfDelCheques = new Map<Id,Subscription__c>();
                for(Subscription__c rec: procsubs){
                    if(!mapSubOfDelCheques.containsKey(rec.id)){
                        mapSubOfDelCheques.put(rec.id,rec);
                    }
                }
                for(Cheque__c rec:procs){
                    if (mapSubOfDelCheques.containsKey(rec.Subscription__c)) {
                        Subscription__c subRec = mapSubOfDelCheques.get(rec.Subscription__c);
                        if(subRec.total_dd_payment__c!=null){
                            subRec.total_dd_payment__c = subRec.total_dd_payment__c - rec.Cheque_Amount__c;
                        }
                    }
                }
                update mapSubOfDelCheques.values();
            }
            //MIrfan@Apiirio, END
            calc.addSubsForProcessing(setSubIds);
            calc.GetSubData();
            calc.Calculate();
            calc.UpdateValues();
            
            DeferredCalculation.inDeferredCalc = false;
        }
    }   
}