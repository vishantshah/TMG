/**
* @author Unknown
* @date Unknown
* @description Scheduler for DDCCA letter extract
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         27/10/2015  //replaced weird static resources config file with custom settings references
Wiktor Czykin 	1.2			18/11/2015	//modified execute method
**/
global class MPPLetterExtractDDCCAScheduler implements Schedulable{
    
    @TestVisible private static Boolean bTestError = false;

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - implementation of schedulable interface method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         26/10/2015  //replaced config file with custom settings
    Wiktor Czykin 	1.2			18/11/2015	//modified batch class constructor call
    ****************************************************************************************/
    global void execute(SchedulableContext sc){
       
        String adminAddress = Constants.MPP_LETTEREXTRACT_ADMINEMAIL_VALUE;
        General__c adminTarget = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_ADMINEMAIL);
        if(adminTarget!=null && String.isNotBlank(adminTarget.Value__c)){
            adminAddress = adminTarget.Value__c;
        }
        try{
            if(Test.isRunningTest() && bTestError){
                throw new TelegraphApplicationException('error');
            }

            String toAddress = Constants.MPP_LETTEREXTRACT_TARGETEMAIL_VALUE;
            General__c extractTargetSetting = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_TARGETEMAIL);
            if(extractTargetSetting!=null && String.isNotBlank(extractTargetSetting.Value__c)){
                toAddress = extractTargetSetting.Value__c;
            }
           
            String replyToAddress = Constants.MPP_LETTEREXTRACT_REPLYTOEMAIL;
            General__c replyToSetting = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_REPLYTOEMAIL);
            if(replyToSetting!=null && String.isNotBlank(replyToSetting.Value__c)){
                replyToAddress = replyToSetting.Value__c;
            }

            Integer batchSize = Constants.MPP_LETTEREXTRACT_BATCHSIZE_VALUE;
            General__c batchSizeSetting = General__c.getInstance(Constants.GENERAL_MPP_LETTEREXTRACT_BATCHSIZE);
            if(batchSizeSetting != null && String.isNotBlank(batchSizeSetting.Value__c) && batchSizeSetting.Value__c.isNumeric()){
                batchSize = Integer.valueOf(batchSizeSetting.Value__c);
            }

            //Calling batch for CC reports
            Database.executeBatch(	new MPPLetterExtractDDCCABatch(	Constants.SUB_ACQUISITION_PAYMENT_CC, 
            														'MPP_CCA_', 
            														MPPLetterExtractDDCCABatch.FILTERTYPE_RECORDTYPE,
            														MPPLetterExtractData.getMPP_CCA_BatchQuery(), 
            														toAddress, 
            														adminAddress, 
            														replyToAddress),
            						batchSize
            );
            
            Database.executeBatch(	new MPPLetterExtractDDCCABatch(	Constants.SUB_ACQUISITION_PAYMENT_DD,
            														'MPP_DD_',
            														MPPLetterExtractDDCCABatch.FILTERTYPE_RECORDTYPE,
            														MPPLetterExtractData.getMPP_DD_BatchQuery(),
            														toAddress, 
            														adminAddress, 
            														replyToAddress),
            						batchSize
            );
        
        }catch(System.Exception e){
            Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
            errorMail.setToAddresses(new List<String>{adminAddress});
            errorMail.setPlainTextBody('The MPPLetterExtractDDCCABatch job failed to schedule: \nError Message: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString());
            errorMail.setSenderDisplayName('DD/CCA Daemon');
            errorMail.setSubject('Error in MPPLetterExtractDDCCAScheduler');
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{errorMail});
            }
        }
    }
}