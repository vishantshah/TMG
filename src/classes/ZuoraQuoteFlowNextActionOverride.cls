/**
* Author:       Wiktor Czykin
* Date:         09/03/2016
* Description:  Class to extend the logic on Next button click within Zuora quote creation flow.
* ******************* Change Log *******************
* Modified by       Change Date
* Lynette Lim       27-04-2016   Modified doUpdate() to allow agents to sell digital subscriptions to Customer with existing in-renewal print subscription
* Wiktor Czykin		22-03-2017   Modified doUpdate()
**/
global class ZuoraQuoteFlowNextActionOverride extends zqu.CreateQuoteController.UpdateRecordPlugin{
	
	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        09/03/2016
	Function    In extra logic it validates that processed subscriber does not have active subscription both from old and new platform
				It also runs records check for old platform records for Registrant type 
	******************* Change Log *******************
	Modified by         Version     Change Date
	Lynette Lim         1.1         27-04-2016   Modified doUpdate() to allow agents to sell digital subscriptions to Customer with existing in-renewal print subscription
	Wiktor Czykin		1.2			22-03-2017   Modified so that it also works if the active (in renewal, pending cancellation) subscription end date is in the past  
	****************************************************************************************/
	global override PageReference doUpdate(SObject record, zqu.PropertyComponentController.ParentController pcc) {
		Savepoint sp = Database.setSavepoint();
		PageReference pr;
		Boolean bIsInsert = false;
        if(record.Id == null){
            bIsInsert = true;
        }

		if(!Test.isRunningTest()){
			pr = super.doUpdate(record, pcc);
		}
		Id accountId = (Id) record.get(Constants.ACCOUNT_FIELD);
		List<Account> lstAccounts = [select Id, Subscriber_Number__c, Subscriber_Digital_Status__c, Subscription_Status__c, RecordTypeId from Account where Id = :accountId];

		Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		if(lstAccounts[0].RecordTypeId != registrantRecordTypeId){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Quote_Flow_Non_registrant_account_error));
			Database.rollback(sp);
			if(bIsInsert) record.Id = null;
			return null;
		}

		String sStatus = AccountUtility.hasAccountActiveSub(lstAccounts[0]);
		if (String.isBlank(sStatus) || sStatus == AccountUtility.STATUS_ACTIVE) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Quote_Flow_Active_subscription_error));
			Database.rollback(sp);
			if(bIsInsert) record.Id = null;
			return null;
		}else if(sStatus == AccountUtility.STATUS_PENDINGCANCELLATION_CONDITIONAL){
        	Date dCancellationSubscription = AccountUtility.isPendingCancellationConversion(lstAccounts[0].Id);
            if(dCancellationSubscription != null && ((Date)record.get(Constants.SERVICE_ACTIVATION_DATE_FIELD)) < dCancellationSubscription.addDays(1)){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Quote_Flow_Pending_cancellation_print_subscription_to_digital_wrong_date));
				Database.rollback(sp);
				if(bIsInsert) record.Id = null;
				return null;
            }
        }else if(sStatus == AccountUtility.STATUS_INRENEWAL_CONDITIONAL){
        	Date dInRenewalSubscription = AccountUtility.isInRenewalConversion(lstAccounts[0].Id);
            if(dInRenewalSubscription != null && ((Date)record.get(Constants.SERVICE_ACTIVATION_DATE_FIELD)) < dInRenewalSubscription.addDays(1)){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Quote_Flow_InRenewal_print_subscription_to_digital_wrong_date));
				Database.rollback(sp);
				if(bIsInsert) record.Id = null;
				return null;
            }
        }
		return pr;
	}
}