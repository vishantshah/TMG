/**
* @author Unknown
* @date Unknown
* @description Batch job generating and sending out csv file with subscription details
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         22/10/2015  //slightly updated updateQueue()
Wiktor Czykin	1.2			18/11/2015	//almost rewritten
Wiktor Czykin   1.3         09/02/2016  //modified execute() 
**/
public class MPPLetterExtractDDCCABatch implements Database.Batchable<SObject>, 
                                                   Database.AllowsCallouts, 
                                                   Database.Stateful{
	
	public static final String FILTERTYPE_RECORDTYPE = 'recordtypeid';
	
	private Map<String, Map<String, String>> mapFilterTypeToValues = new Map<String, Map<String, String>>{
		FILTERTYPE_RECORDTYPE => new Map<String, String>{	RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()) => Constants.RECTYPE_SUBSCRIPTION_LOWSTART,
															RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName()) => Constants.RECTYPE_SUBSCRIPTION_DEFAULT 
		}
	};
	
	private Map<String, MPPLetterExtractData.BatchLogger> mapConditionToFileLogger = new Map<String, MPPLetterExtractData.BatchLogger>();   
	private MPPLetterExtractData.BatchLogger log;
	
	private String sFilterType;
	private String sEmailTitleExtractType;
	private String query;
	private String toAddress;
    private String replyToAddress;
    private String adminAddress;
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/11/2015  //modified the constructor - new parameters added, logic modified
    ****************************************************************************************/
    public MPPLetterExtractDDCCABatch(String sEmailTitleExtractType, String sFileName, String sFilterType, String query, String toAddress, String adminAddress, String replyToAddress){
        if(!mapFilterTypeToValues.containsKey(sFilterType)) throw new TelegraphApplicationException(Label.MPP_Letter_Extract_No_matching_filter);
        
        this.query = query;
        this.toAddress = toAddress;
        this.replyToAddress = replyToAddress;
        this.adminAddress = adminAddress;
        this.sFilterType = sFilterType;
        this.sEmailTitleExtractType = sEmailTitleExtractType;
        this.log = new MPPLetterExtractData.BatchLogger(MPPLetterExtractData.createFileName('MPPLetterExtractDDCCABatchLog', 'log', 1), null);
        
        Map<String, String> mapForFilter = mapFilterTypeToValues.get(sFilterType);
        for(String sFilterKey : mapForFilter.keySet()){
        	String sGeneratedFileName = MPPLetterExtractData.createFileName(mapForFilter.get(sFilterKey)+sFileName, 'csv', 1);
        	MPPLetterExtractData.BatchLogger bl = new MPPLetterExtractData.BatchLogger(sGeneratedFileName, MPPLetterExtractData.CSV_DDCCA_HEADER);
        	mapConditionToFileLogger.put(sFilterKey, bl);
        }      
    }

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - implementation of start method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {       
        return Database.getQueryLocator(this.query); 
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - implementation of execute method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/11/2015  //added split logic based on filter parameter
    Wiktor Czykin   1.2         08/02/2016  //changed comparison identifier from MppSubscriptionId to TSNumber
    ****************************************************************************************/
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        //Build the paramMap for the MPP rest GetPaymentDetails api - collection of TSNumbers.
        String paramMap = MPPLetterExtractData.buildParamMap((List<Subscription__c>)scope);
        Map<String, MPPInterfaceHTTP.PaymentDetailResult> paymentMPPMap = new Map<String, MPPInterfaceHTTP.PaymentDetailResult>();
        List<Subscription__c> subQueue = new List<Subscription__c>();
        MPPInterfaceHTTP mppRest = new MPPInterfaceHTTP();
        
        /*  Get the payment details from MPP and map back to the csv. Please note we will need to map back the 
            premium subscription id and not the tsnumber to paymentMPPMap.
        */
        try{
            for(MPPInterfaceHTTP.PaymentDetailResult a : mppRest.getBulkPaymentDetailResult(paramMap)){
                paymentMPPMap.put(a.tsNumber.toLowerCase(), a);
            }
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
            String msg = '### MPP error returned from get MPPInterfaceHTTP.GetBulkPaymentDetailResult API ###: '+'Error Code: ' + e.getErrorCode() + ' | Error Message: ' + e.getErrorMessage();
            this.log.addLog(msg);
            System.debug(msg);
        }catch(System.Exception e){
            String msg = '### SFDC error returned from get MPPInterfaceHTTP.GetBulkPaymentDetailResult API ###: ' + e.getMessage() + ' : ' + e.getStackTraceString();
            this.log.addLog(msg);
            System.debug(msg);
        }
        
        //The returned MPP payment map should match the premium subscription id.
        if(!paymentMPPMap.isEmpty()){
            for(Subscription__c sub : (List<Subscription__c>)scope){                             
                String tsNumber = sub.Subscriber__r.Subscriber_Number_static__c.toLowerCase();
                String sValueToMap = (String)sub.get(this.sFilterType);
                
                if(paymentMPPMap.containsKey(tsNumber)){
                    //Retrieve the payment details and create the record in the csv file.
                    MPPInterfaceHTTP.PaymentDetailResult payment = paymentMPPMap.get(tsNumber);
                    
                    if(mapFilterTypeToValues.get(this.sFilterType).containsKey(sValueToMap) && mapConditionToFileLogger.containsKey(sValueToMap)){
                    	mapConditionToFileLogger.get(sValueToMap).addCSVData(MPPLetterExtractData.createCSV_Row(sub, payment));
                    }
                    subQueue.add(sub);
                }else{
                    String msg = '### Cannot find MPP payment detail for Subscription[' + sub.Id + '][' + tsNumber + '][' + sub.Name + '] ###'; 
                    this.log.addLog(msg);
                    System.debug(msg);
                }
            }
            this.updateQueue(subQueue);
        }else{
            this.batchLog((List<Subscription__c>)scope, '### No MPP details found ###');
        }
    } 
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - implementation of execute method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/11/2015  //split logic generating exception email, added attachments generation based on the respective BatchLogger records 
    ****************************************************************************************/
    public void finish(Database.BatchableContext bc) {
        //Batch send emails.
        List<Messaging.SingleEmailMessage> emailQueue = new List<Messaging.SingleEmailMessage>();
        List<Messaging.EmailfileAttachment> lstAdminFileAttachments = new List<Messaging.EmailfileAttachment>();
        List<Messaging.EmailfileAttachment> lstUserFileAttachments = new List<Messaging.EmailfileAttachment>();
        
        Messaging.EmailfileAttachment attachment;
        Boolean bSendAdminEmail = false;
        Boolean bNoRecordsToExtract = false;
        if(this.log != null && this.log.logHeader != this.log.getLog()){
	        //The log file should only be sent to the administration salesforce group.
	        attachment = new Messaging.EmailfileAttachment();
	        attachment.setBody(Blob.valueOf(this.log.getLog()));       
	        attachment.setContentType('text/plain');
	        attachment.setFileName(this.log.getFileName());            
	        lstAdminFileAttachments.add(attachment);
	        bSendAdminEmail = true;
        }    
        
        if(!this.mapConditionToFileLogger.isEmpty()){
	        for(MPPLetterExtractData.BatchLogger bl : this.mapConditionToFileLogger.values()){
		        if(bl.isCSVDataValid()){
		            attachment = new Messaging.EmailfileAttachment();       
		            attachment.setBody(Blob.valueOf(bl.getCSVData()));     
		            attachment.setContentType('text/csv');
		            attachment.setFileName(bl.getFileName());         
		            lstUserFileAttachments.add(attachment);
		        }
       		}
        }
        
        if(!lstUserFileAttachments.isEmpty()){
        	Messaging.SingleEmailMessage defaultMail = new Messaging.SingleEmailMessage();
            defaultMail.setToAddresses(this.toAddress.split(','));
            defaultMail.setPlainTextBody('The '+this.sEmailTitleExtractType+' csv file is attached.');
            defaultMail.setSenderDisplayName(this.sEmailTitleExtractType+' PDD Extract');
            defaultMail.setReplyTo(this.replyToAddress);
            defaultMail.setSubject('Please mail merge these '+this.sEmailTitleExtractType+' records');
            defaultMail.setFileAttachments(lstUserFileAttachments);
            emailQueue.add(defaultMail);    
        }else{
        	bNoRecordsToExtract = true;
            bSendAdminEmail = true;
        }
        
        if(bSendAdminEmail){
        	Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
            errorMail.setToAddresses(this.adminAddress.split(','));
            String sBody = 'There were issues with the extract.';
            if(bNoRecordsToExtract){
            	sBody += '\n There were no records to extract. No '+this.sEmailTitleExtractType+' records detected.';
            }
            
            errorMail.setPlainTextBody(sBody);     
            errorMail.setSenderDisplayName('DD/CCA Daemon');
            errorMail.setReplyTo(this.replyToAddress);
            String sSubject = 'Issues with the extract. '; 
            if(bNoRecordsToExtract){
            	sSubject += 'No '+this.sEmailTitleExtractType+' records to merge.';
            }
            errorMail.setSubject(sSubject);
            if(!lstAdminFileAttachments.isEmpty()){
            	errorMail.setFileAttachments(lstAdminFileAttachments);
            }
            emailQueue.add(errorMail);
        }
        
        if(!emailQueue.isEmpty()){
            Messaging.sendEmail(emailQueue);
        }
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - puts all records processed into the log file
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         18/11/2015  //changed to use specific log file
    ****************************************************************************************/
    public void batchLog(List<Subscription__c> subs, String msg){
        for(Subscription__c sub :subs){
            this.log.addLog('### Subscription[' + sub.Id + '][' + sub.MPP_Premium_Subscription_ID__c + '] - ' + msg);
        }
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - updates subscription and logs failures
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/10/2015  //modified update type to be partial success one as further code suggests
    Wiktor Czykin   1.2         18/11/2015  //changed to use specific log file
    ****************************************************************************************/
    @TestVisible private void updateQueue(List<Subscription__c> subQueue){
        if(subQueue == null || subQueue.isEmpty()){
            this.log.addLog('### No Subscriptions can be mapped ###');
            return;
        }
        SubscriberPortal.SAM_WS_UPDATE = true;
        List<Database.SaveResult> result = Database.update(subQueue, false);
        for(Integer i = 0; i < result.size(); i++){
            if(!result[i].success){
                this.log.addLog('### Subscription[' + subQueue[i].Id + '][' + subQueue[i].MPP_Premium_Subscription_ID__c + '] - update failed ###: ' + String.valueOf(result[i].errors));
            }
        }
    }
}