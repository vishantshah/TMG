/**
* @author Unknown
* @date Unknown
* @description Batch job generating and sending out csv file with subscription details
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         22/10/2015  //slightly updated updateQueue()
**/
global with sharing class MPPLetterExtractDigtalBatch extends MPPLetterExtractData.BatchLogger 
													  implements Database.Batchable<SObject>,  
															     Database.Stateful{
	private final String query;
	private final String toAddress;
	private final String replyToAddress;
	private final String adminAddress;
	
	public MPPLetterExtractDigtalBatch(String toAddress, String adminAddress, String replyToAddress){
		super(MPPLetterExtractData.createFileName('MPP_DIGITAL_SUBS_', 'csv', 0), MPPLetterExtractData.CSV_DIGITAL_SUBSCRIBER_HEADER);
		this.query = MPPLetterExtractData.getMPP_Digital_BatchQuery();
		this.toAddress = toAddress;
		this.replyToAddress = replyToAddress;
		this.adminAddress = adminAddress;
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc){		
		return Database.getQueryLocator(this.query); 
	}
	
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<MPPLetterExtractData.SubscriberTransaction> subTransactionMap = new List<MPPLetterExtractData.SubscriberTransaction>();
		List<MPPLetterExtractData.DigitalSubscriber> digitalCSVData = new List<MPPLetterExtractData.DigitalSubscriber>();
		Set<Account> accQueue = new Set<Account>();
		
		for(Account acc :(List<Account>)scope){
			MPPLetterExtractData.SubscriberTransaction wrapper = new MPPLetterExtractData.SubscriberTransaction(acc);
			for(MPP_Transaction_History__c tran :acc.MPP_Transaction_Histories__r){
				//Find out which frequency these transaction histories are in.
				String freq = MPPLetterExtractData.getDigitalFrequency(tran.Total_Price__c);
				if(freq.equals(MPPLetterExtractData.freqType.MONTHLY.name())){
					wrapper.monthly.add(tran);
				}else if(freq.equals(MPPLetterExtractData.freqType.ANNUAL.name())){
					wrapper.annual.add(tran);
				}	
			}
			subTransactionMap.add(wrapper);
		}
		
		//Check if there are any transactions to map.
		if(subTransactionMap.isEmpty()){
			//No Accounts where mapped?
			addLog('### No Accounts can be mapped for query ###');
			return;
		}
		
		/*
			We should now have a list of monthly or annual transactions check the following:
			 * Annual Subscribers: at least 1 txn history (with status = success), and Subscriber.country = UK, and Subscriber.isDigitalLetterExtracted = false
     		 * Monthly Subscribers: at least 2 txn history (with status = success),  and Subscriber.country = UK, and Subscriber.isDigitalLetterExtracted = false
		*/
		for(SubscriberTransaction subData :subTransactionMap){
			if(subData.monthly.size() >= 2){
				MPPLetterExtractData.DigitalSubscriber row = new MPPLetterExtractData.DigitalSubscriber();
				row.acc = subData.acc;
				row.subStartDate = subData.monthly[0].CreatedDate;
				digitalCSVData.add(row);
			}
			if(!subData.annual.isEmpty()){
				MPPLetterExtractData.DigitalSubscriber row = new MPPLetterExtractData.DigitalSubscriber();
				row.acc = subData.acc;
				row.subStartDate = subData.annual[0].CreatedDate;
				digitalCSVData.add(row);
			}
		}
		
		if(digitalCSVData.isEmpty()){
			//No digital subscribers where mapped?
			addLog('### No Subscriber transactions can be mapped ###');
			return;
		}
		
		for(MPPLetterExtractData.DigitalSubscriber digiSub :digitalCSVData){
			try{
				addCSVData(MPPLetterExtractData.createCSV_Row(digiSub));
				accQueue.add(digiSub.acc);
			}catch(System.Exception e){
				String msg = '### Account[' + digiSub.acc.Id + '] - failed to add row to csv ###: ' + e.getMessage();
				addLog(msg);
				System.debug(msg);
			}
		}
		updateQueue(accQueue);
	}
	
	global void finish(Database.BatchableContext bc) {
		//Batch send emails.
		List<Messaging.SingleEmailMessage> emailQueue = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailfileAttachment> fileAttachments = new List<Messaging.EmailfileAttachment>();
		Messaging.EmailfileAttachment attachment;
		Blob debugLog = Blob.valueOf(this.getLog());
		//The log file should only be sent to the administration salesforce group.
		String logFile = MPPLetterExtractData.retrieveFileName(this.getFileName()) + '.log';
		
		attachment = new Messaging.EmailfileAttachment();
		attachment.setBody(debugLog);		
		attachment.setContentType('text/plain');
		attachment.setFileName(logFile);			
		fileAttachments.add(attachment);	
		
		if(this.isCSVDataValid()){
			Blob dsLetterCSV = Blob.valueOf(this.getCSVData());
			attachment = new Messaging.EmailfileAttachment();		
			attachment.setBody(dsLetterCSV);		
			attachment.setContentType('text/csv');
			attachment.setFileName(this.getFileName());			
			fileAttachments.add(attachment);
			
			Messaging.SingleEmailMessage defaultMail = new Messaging.SingleEmailMessage();
			defaultMail.setToAddresses(this.toAddress.split(','));
			defaultMail.setPlainTextBody('The digital subscribers csv file is attached.');
			defaultMail.setSenderDisplayName('Digital Letter Extract Daemon');
			defaultMail.setReplyTo(this.replyToAddress);
			defaultMail.setSubject('Please mail merge these digital subscriber records');
			defaultMail.setFileAttachments(new List<Messaging.EmailfileAttachment>{fileAttachments[1]});
			emailQueue.add(defaultMail);
			
			Messaging.SingleEmailMessage adminMail = new Messaging.SingleEmailMessage();
			adminMail.setToAddresses(this.adminAddress.split(','));
			adminMail.setPlainTextBody('The digital subscribers csv file is attached.');
			adminMail.setSenderDisplayName('Digital Letter Extract Daemon');
			adminMail.setSubject('Please mail merge these digital subscriber records');
			adminMail.setFileAttachments(fileAttachments);
			emailQueue.add(adminMail);
		}else{
			Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
			errorMail.setToAddresses(this.adminAddress.split(','));
			errorMail.setPlainTextBody('No digital subscriber records detected. Please check the job status in Salesforce, or contact your system administrator.');
			errorMail.setSenderDisplayName('Digital Letter Extract Daemon');
			errorMail.setReplyTo(this.replyToAddress);
			errorMail.setSubject('No digital subscriber records to merge');
			errorMail.setFileAttachments(fileAttachments);
			emailQueue.add(errorMail);
		}
		
		if(!emailQueue.isEmpty()){
			//Send email.
			Messaging.sendEmail(emailQueue);
		}
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - updates subscription and logs failures
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/10/2015  //modified update type to be partial success one as further code suggests
    ****************************************************************************************/
	public void updateQueue(Set<Account> accQueue){
		if(accQueue == null || accQueue.isEmpty()){
			addLog('### No Accounts can be mapped for update ###');
			return;
		}
		SubscriberPortal.SAM_WS_UPDATE = true;
		List<Account> accList = new List<Account>(accQueue);
		List<Database.SaveResult> result = Database.update(accList, false);
		for(Integer i = 0; i < result.size(); i++){
			if(!result[i].success){
				addLog('### Account[' + accList[i].Id + '] - update failed in SFDC, but added to csv file ###: ' + String.valueOf(result[i].errors));
			}
		}
	}
}