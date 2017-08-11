/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         30/07/2015  //changed the flag preventing the trigger from running
**/
global class UpdateChequeStatusBatch implements Database.Batchable<sObject>{
   global final String Query;
   global final String[] Field;
   global final String[] Value;
   
   global UpdateChequeStatusBatch(String q, String[] f, String[] v){
      Query=q; Field=f;Value=v;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, 
      List<Cheque__c> scope){
      ChequeTriggerHandler.getInstance().isExecuting = true;//ensures that ChequeToUpdateTotalDDPayment trigger does not update subscription.total_dd_payment__c
   
      system.debug('cheque ' + scope);
      for(Cheque__c s : scope){         
            s.put(Field[0],Value[0]); 
            if (s.Cheque_Refund_Reason__c == null || s.Cheque_Refund_Reason__c ==  '')
                s.put(Field[1],Value[1]);        
      }      
      update scope;
      ChequeTriggerHandler.getInstance().isExecuting = false;
   }

   global void finish(Database.BatchableContext BC){}
}