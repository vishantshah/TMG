/* ------------------------------------------------------------------------------
   Name:        SubscriptionStatusInRenewalScheduler.cls
   Description: Scheduler that runs SubscriptionStatusInRenewalBatch

   Date         Version Author              Summary of Changes
   -----------  ------- -----------------   -------------------------------------
   16/10/2015   1.1     Cristina Anghenie   scheduler that runs the SubscriptionStatusInRenewal batch
   29/12/2016   1.2     Wiktor Czykin       added offset param to scheduler
--------------------------------------------------------------------------------- */
global class SubscriptionStatusInRenewalScheduler implements Schedulable {

    private Integer iOffset;
    private Integer iBatchSize;
    private Boolean bSendNotifications = true;

    public SubscriptionStatusInRenewalScheduler(){}

    public SubscriptionStatusInRenewalScheduler(Integer iOffset, Integer iBatchSize, Boolean bSendNotifications){
        if(iOffset != null){
            this.iOffset = iOffset;
        }
        if(iBatchSize != null && iBatchSize > 0){
            this.iBatchSize = iBatchSize;
        }else{
            this.iBatchSize = 200;
        }
        if(bSendNotifications != null){
            this.bSendNotifications = bSendNotifications;
        }
    }

    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 27/11/2015
    Version - 1.1
    Function - method that schedule SubscriptionStatusInRenewal batch to run every saturday at 00
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   30/12/2016  //added extra params usage
    *************************************************************************************/
    global void execute(SchedulableContext sc) {
        String adminAddress = Constants.MPP_LETTEREXTRACT_ADMINEMAIL_VALUE;
        General__c adminTarget = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_ADMINEMAIL);
        if(adminTarget!=null && String.isNotBlank(adminTarget.Value__c)){
            adminAddress = adminTarget.Value__c;
        }

        SubscriptionStatusInRenewalBatch subsBatch;
        if(this.iOffset != null){
            subsBatch = new SubscriptionStatusInRenewalBatch(this.iOffset, this.bSendNotifications);
        }else{
            subsBatch = new SubscriptionStatusInRenewalBatch();
        }

        try{
            Database.executebatch(subsBatch, iBatchSize);
        }catch(System.Exception e){
            Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
            errorMail.setToAddresses(new List<String>{adminAddress});
            errorMail.setPlainTextBody('The SubscriptionStatusInRenewalBatch job failed to schedule: \nError Message: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString());
            errorMail.setSubject('Error in SubscriptionStatusInRenewalBatch');
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{errorMail});
            }
        }
   }
}
