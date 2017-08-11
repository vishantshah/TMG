/**
Name: SubscriptionStatusQueueable
* @author Wiktor Czykin
* @date 31/03/2015
* @description Queueable job to update Subscription_Status__c on Subscription__c object
##########Change Log##########
Modified by     Version     Change Date
Wiktor Czykin	1.1			24/06/2015	//modified handleFutureCallout() - removed custom settings dependency on SAM callout
Michal Szewczyk	1.2			25/06/2016	//modified handleFutureCallout() - replaced callSamForSingleUpdate with callSamForUpdateAsync
Wiktor Czykin   1.3         25/07/2016  //modified withrawal condition to be based on Offered sub start date
Wiktor Czykin   1.4			31/01/2017	//modified handleFutureCallout() - method called signature change
*/
public without sharing class SubscriptionStatusQueueable implements Queueable{

	@TestVisible private Map<Id, SubscriptionStatusQueueableResult> mapFailedRecords = new Map<Id, SubscriptionStatusQueueableResult>();
	public static final Integer ERROR_LIMIT = 200;
	public static final Integer DEFAULT_QUEUE_SIZE = 1000;
	private static final String STARTDATE_RULE_STATUS = Constants.SSTATUS_PENDING;
	private static final Set<String> ENDDATE_RULE_STATUSES = new Set<String>{	Constants.SSTATUS_PENDING,
																				Constants.SSTATUS_ACTIVE,
																				Constants.SSTATUS_IN_RENEWAL
	};
	private static final String WITHDRAWAL_RULE_STATUS = Constants.SSTATUS_OFFERED;

	@TestVisible private Integer iQueueSize{get;set;}
    @TestVisible private Boolean bTestFailure{
    	get{
    		if(this.bTestFailure == null){
    			return false;
    		}else{
    			return bTestFailure;
    		}
    	}
    	set;
    }

    private Enum Types {StartDate, EndDate, Withdrawal}

    /***************************************************************************************
	Developer - Wiktor Czykin
	Date Created -  31/03/2015
	Version - 1.0
	Function - 	Default constructor. Accepts queue size (number records to be fetched by iteration) and map of failed records (if chained queueu)
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
  	public SubscriptionStatusQueueable(Integer iQueueSize, Map<Id, SubscriptionStatusQueueableResult> mapFailedRecords){
	    if(mapFailedRecords != null){
	    	this.mapFailedRecords = mapFailedRecords;
	    }
	    this.iQueueSize = iQueueSize!=null?iQueueSize:DEFAULT_QUEUE_SIZE;
	    this.iQueueSize ++;
  	}


  	/***************************************************************************************
	Developer - Wiktor Czykin
	Date Created -  31/03/2015
	Version - 1.1
	Function - 	Queueable execute method implementation - main logic
	############Change Log#############
	Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/07/2016  //changed the rule for withdrawn
	****************************************************************************************/
  	public void execute(QueueableContext qctx){
  		Boolean bContinue = false;

  		Date dToday = Date.today();

    	Integer iDaysBackEndDateCheck = Constants.SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK;
    	Integer iDaysWithdrawalCheck = Constants.SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK;

    	General__c endDateSetting = General__c.getInstance(Constants.SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK_SETTING);
    	General__c withdrawalSetting = General__c.getInstance(Constants.SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK_SETTING);
    	if(endDateSetting != null && String.isNotBlank(endDateSetting.Value__c) && endDateSetting.Value__c.isNumeric()){
    		iDaysBackEndDateCheck =  Integer.valueOf(endDateSetting.Value__c);
    	}

    	if(withdrawalSetting != null && String.isNotBlank(withdrawalSetting.Value__c) && withdrawalSetting.Value__c.isNumeric()){
    		iDaysWithdrawalCheck = Integer.valueOf(withdrawalSetting.Value__c);
    	}

    	Date dYesterday = dToday.addDays(-iDaysBackEndDateCheck);
    	Date dWithrawal = dToday.addDays(-iDaysWithdrawalCheck);
		String sQuery = 'select Id, Name, Subscription_Status__c, Previous_Subscription_Expiry__c, Start_Date__c, End_Date__c, Subscriber__c from Subscription__c'
						+' where ((Start_Date__c = :dToday and Subscription_Status__c = :STARTDATE_RULE_STATUS)'
						+' or (End_Date__c = :dYesterday and Subscription_Status__c in :ENDDATE_RULE_STATUSES)'
						+' or (Start_Date__c = :dWithrawal and Subscription_Status__c = :WITHDRAWAL_RULE_STATUS)) ';

		if(this.mapFailedRecords != null && !this.mapFailedRecords.isEmpty()){
			Set<Id> setIdFailedIds = this.mapFailedRecords.keySet();
			sQuery += '  and  Id not in :setIdFailedIds';
		}
		sQuery += ' limit :iQueueSize';

	    Set<Id> setStartDateRecordIds = new Set<Id>();
		Set<Id> setEndDateRecordIds = new Set<Id>();
		Set<Id> setWithdrawalRecordIds = new Set<Id>();

		List<Subscription__c> lstSubscriptions = Database.query(sQuery);
		if(lstSubscriptions.size() == this.iQueueSize){//means that there are still more records in the
			bContinue = true;
			lstSubscriptions.remove(lstSubscriptions.size()-1);
		}

		Map<Id, Subscription__c> mapSubscriptions = new Map<Id, Subscription__c>(lstSubscriptions);
		List<Subscription__c> lstToUpdate = new List<Subscription__c>();

		for(Subscription__c sub : lstSubscriptions){
			//scenario 1: Start Date == Today
			if(sub.Start_Date__c == dToday && sub.Subscription_Status__c == STARTDATE_RULE_STATUS){
				lstToUpdate.add(new Subscription__c(Id = sub.Id, Subscription_Status__c = Constants.SSTATUS_ACTIVE));
				setStartDateRecordIds.add(sub.Id);
			//scenario 2: End Date == Yesterday and (Status = Pending or Status = Active or Status = In Renewal)
			//assumption here that End Date__c cannot be before Start_Date__c (else 1 and 2 if could overlap and 2nd can potentially be not exeuted)
			}else if(sub.End_Date__c == dYesterday && ENDDATE_RULE_STATUSES.contains(sub.Subscription_Status__c)){
				lstToUpdate.add(new Subscription__c(Id = sub.Id, Subscription_Status__c = Constants.SSTATUS_LAPSED));
				setEndDateRecordIds.add(sub.Id);
			//scenario 3: Previous Subscription Expiry date is 91 days ago and subscription status is Offered
        }else if(sub.Start_Date__c == dWithrawal && sub.Subscription_Status__c == WITHDRAWAL_RULE_STATUS){
				lstToUpdate.add(new Subscription__c(Id = sub.Id, Subscription_Status__c = Constants.SSTATUS_WITHDRAWN));
				setWithdrawalRecordIds.add(sub.Id);
			}
		}
		//I don't like such conditions but else there would be a huge block of code untested
		if(Test.isRunningTest() && this.bTestFailure){
			for(Subscription__c sub : lstToUpdate){
				sub.Start_Date__c = null;
			}
		}

		if(!lstToUpdate.isEmpty()){
			AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
			ath.bRunAPI = false;

			SubscriptionTriggerHandler sth = SubscriptionTriggerHandler.getInstance();
			sth.bRunAPI = false;

			List<Database.SaveResult> lstResults = Database.update(lstToUpdate, false);
			Set<Id> setSuccesses = new Set<Id>();
			for(Integer i = 0; i < lstResults.size(); i++){
				Id subId = lstToUpdate[i].Id;
				if(!lstResults[i].isSuccess() && this.mapFailedRecords.size() <= ERROR_LIMIT){
					String sError = '';
					for(Database.Error err : lstResults[i].getErrors()){
						sError += err.getMessage()+ ' ';
			        }
					SubscriptionStatusQueueableResult result = new SubscriptionStatusQueueableResult(mapSubscriptions.get(subId), lstToUpdate[i], sError);

					if(setStartDateRecordIds.contains(subId)){
						result.sType = Types.StartDate.name();
					}else if(setEndDateRecordIds.contains(subId)){
						result.sType = Types.EndDate.name();
					}else if(setWithdrawalRecordIds.contains(subId)){
						result.sType = Types.Withdrawal.name();
					}

					this.mapFailedRecords.put(subId, result);
				}else{
					Id accId = mapSubscriptions.get(subId).Subscriber__c;
					if(accId != null){
						setSuccesses.add(mapSubscriptions.get(subId).Subscriber__c);
					}
				}
			}
			//future callout for successes
			if(!setSuccesses.isEmpty()){
				System.debug('DEBUG:SubscriptionStatusQueueable:Call out records count:'+setSuccesses.size());
				this.handleFutureCallout(setSuccesses);
			}
		}

		if(bContinue && this.mapFailedRecords.size()<=ERROR_LIMIT){
			System.enqueueJob(new SubscriptionStatusQueueable(this.iQueueSize-1, this.mapFailedRecords));//dont
		}else{
			this.finish();
		}
  	}

  	/***************************************************************************************
	Developer - Wiktor Czykin
	Date Created -  31/03/2015
	Version - 1.3
	Function - separated method to do a callout logic for successful suscription updates in this iteration
	############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			24/06/2015	// removed OverrideSAMUpdate__c settings
	Michal Szewczyk	1.2			25/06/2015	// replaced callSamForSingleUpdate with callSamForUpdateAsync for one acc
	Wiktor Czykin	1.3			31/01/2017  // callSamForUpdateAsync() signature change
	****************************************************************************************/
  	private void handleFutureCallout(Set<Id> setAccountIds){

            if((Label.ByPassSamUpdatesForUser == null || Label.ByPassSamUpdatesForUser != UserInfo.getUserName()) && (Label.SamUserId == null || Label.SamUserId != UserInfo.getUserName())){
                UpdateSamUserDetailsBatch.callSamForUpdateAsync(setAccountIds, true, false);
            }
  	}

  	/***************************************************************************************
	Developer - Wiktor Czykin
	Date Created -  31/03/2015
	Version - 1.0
	Function - sends email at the end of queued job
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
  	private void finish(){
  		if(this.mapFailedRecords.isEmpty()) return;

		List<String> lstExtraTo = new List<String>();
		General__c recipient = General__c.getInstance(Constants.SUBSCRIPTION_STATUS_BATCH_ERROR_USERID);
		if(recipient != null && String.isNotBlank(recipient.Value__c)){
			lstExtraTo.add(recipient.Value__c);
		}
		String sHtml = '<html><head></head><body>';

		Map<String, String> mapErrors = new Map<String, String>();
		for(SubscriptionStatusQueueableResult res : this.mapFailedRecords.values()){
			if(!mapErrors.containsKey(res.sType)){
				mapErrors.put(res.sType, '');
			}
			String sErrorRow = '<tr><td>'+res.newSubscription.Id+'</td><td>'+res.oldSubscription.Subscription_Status__c+'</td><td>'+res.newSubscription.Subscription_Status__c+'</td><td>'+res.sError+'</td></tr>';
			mapErrors.put(res.sType, mapErrors.get(res.sType) + sErrorRow);
		}
		String sTypeErrorMerged = '';
		for(String sType : mapErrors.keySet()){
			sTypeErrorMerged 	+= String.format(Label.Subscription_Status_Batch_Finish_email_content_section, new List<String>{sType})
								+ String.format(Label.Subscription_Status_Batch_Finish_email_section_table, new List<String>{mapErrors.get(sType)});
		}
		sHtml += String.format(Label.Subscription_Status_Batch_Finish_email_content, new List<String>{sTypeErrorMerged});
		sHtml +='</body></html>';

		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setSubject(Label.Subscription_Status_Batch_Finish_Email_Subject);
		email.setTargetObjectId(System.UserInfo.getUserId());
		if(!lstExtraTo.isEmpty()){
			email.setToAddresses(lstExtraTo);
		}
		email.setHTMLBody(sHtml);
		email.setSaveAsActivity(false);
		if(!Test.isRunningTest()){
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		}
  	}

  	/**
	Name: SubscriptionStatusQueueableResult
	* @author Wiktor Czykin
	* @date 31/03/2015
	* @description 	Helper to show errors easier
	##########Change Log##########
	Modified by     Version     Change Date
	*/
	public class SubscriptionStatusQueueableResult{

		public Subscription__c oldSubscription{get;set;}
		public Subscription__c newSubscription{get;set;}
		public String sType{get;set;}
		public String sError{get;set;}

		/***************************************************************************************
		Developer - Wiktor Czykin
		Date Created -  31/03/2015
		Version - 1.0
		Function - 	Default constructor. Just initializes all params.
		############Change Log#############
		Modified by     Version     Change Date
		****************************************************************************************/
		public SubscriptionStatusQueueableResult(Subscription__c oldVal, Subscription__c newVal, String sError){
			this.oldSubscription = oldVal;
			this.newSubscription = newVal;
			this.sError = sError;
		}
	}
}
