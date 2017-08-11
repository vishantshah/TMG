/* ------------------------------------------------------------------------------
   Name:        CreditCardExpiryDateScheduler.cls
   Description: Scheduler that runs CreditCardExpiryDateBatch

   Date         Version Author              Summary of Changes 
   -----------  ------- -----------------   -------------------------------------
   16/10/2015   1.1     Cristina Anghenie   scheduler that runs the CreditCardExpiryDate batch  
--------------------------------------------------------------------------------- */
global class CreditCardExpiryDateScheduler implements Schedulable {
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 16/11/2015
    Version - 1.0
    Function - method that schedule CreditCardExpiryDate batch to run every sunday at 9PM
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         19/11/2015  //add batch size when executing
    *************************************************************************************/
    global void execute(SchedulableContext sc) {
        String adminAddress = Constants.MPP_LETTEREXTRACT_ADMINEMAIL_VALUE;
        General__c adminTarget = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_ADMINEMAIL);
        if(adminTarget!=null && String.isNotBlank(adminTarget.Value__c)){
            adminAddress = adminTarget.Value__c;
        }
        Integer batchSize = Constants.MPP_LETTEREXTRACT_BATCHSIZE_VALUE;
        General__c batchSizeSetting = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_BATCHSIZE);
        if(batchSizeSetting != null && String.isNotBlank(batchSizeSetting.Value__c) && batchSizeSetting.Value__c.isNumeric()){
            batchSize = Integer.valueOf(batchSizeSetting.Value__c);
        }
        
        CreditCardExpiryDateUpdateBatch ccBatch = new CreditCardExpiryDateUpdateBatch();
        try{
            database.executebatch(ccBatch,batchSize);
        }catch(System.Exception e){
            Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
            errorMail.setToAddresses(new List<String>{adminAddress});
            errorMail.setPlainTextBody('The CreditCardExpiryDateUpdateBatch job failed to schedule: \nError Message: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString());
            errorMail.setSubject('Error in CreditCardExpiryDateScheduler');
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{errorMail});
            }
        }
   }
}