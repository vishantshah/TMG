/**
* @author Unknown
* @date Unknown
* @description Handler class for Subscription__c trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         10/02/2015  //made sure singleton pattern actually works, removed useless class call, got rid of one external helper (moved one method here).
Wiktor Czykin   1.2         11/02/2015  //binned Pawan's filtering code
Wiktor Czykin   1.3         30/03/2015  //modified updateSamSubscriptionDetails()
Wiktor Czykin   1.4         01/05/2015  //fixed updateMPP_CurrentPayScheduleEndDateOnParentAccount()
Wiktor Czykin   1.5         05/06/2015  //modified handleRenewals()
Cristina Popescu1.6         10/06/2015  //update updateSamSubscriptionDetails method to fire only if the account have an email address associated with
Wiktor Czykin   1.7         15/06/2015  //modified startDateValidation()
Wiktor Czykin   1.8         18/06/2015  //modified deferredCalculation()
Wiktor Czykin   1.9         30/07/2015  //added bDeferredCalculationSkip flag to replace old lock class flag
Cristina Anghenie2.0        11/09/2015  //add new method when subs moves from Pending Cancellation to Cancelled
Cristina Anghenie2.1        24/09/2015  //Cancel payment schedules when subscription moves to Pending Cancellation
Cristina Anghenie2.2        18/09/2015  //create method to update incentive description field on subscription before status moves to pending
Wiktor Czykin   2.3         05/09/2015  //added updateLowStartEndDate() method
Wiktor Czykin   2.4         08/11/2015  //made startDateValidation() public
Wiktor Czykin   2.5         13/01/2016  //removed setGiftDonor()
Pawel Chrzanowski   2.6     21/03/2016  //added setupTCodeProductRelation()
Michal Szewczyk 2.7         28/04/2016  //modified updateSamSubscriptionDetails()
Pawel Chrzanowski 2.8       29/04/2016  //added setDefaultPlan()
Gavin Palmer     2.9        31/05/2016  // added validateAgainstProductPrice()
Michal Szewczyk  3.0        13/06/2016  //modified subscriptionInRenewalCreation()
Michal Szewczyk  3.1        14/06/2016  //added checkProduct()
Wiktor Czykin    3.2        14/07/2016  //modified default Plan population
Pawel Chrzanowski   3.3     25/07/2016  //added updateOutboundRenewalCases() 
Wiktor Czykin    3.4        27/09/2016  //modified setDefaultPlan() and reused it in on beforeUpdate
Michal Szewczyk   3.5       20/10/2016  //Added bOcCaseUpdateSkip flag  and changed updateOutboundRenewalCases()
Pawel Chrzanowski 3.6       29/11/2016  //modified updateOutboundRenewalCases()
Wiktor Czykin    3.7        31/01/2017  //modified updateSamSubscriptionDetails()
Vishant Shah      3.8       12/01/2017  removed updateStartDateForAcquisition method
Vishant Shah      3.8       09/02/2017  //code improvments to reduce soql queries in execution on startDateValidation()
Pawel Chrzanowski 3.9       28/02/2017  modified setDefaultPlan() and removed it from update
Wiktor Czykin   4.0         03/03/2017  //modified setupTCodeProductRelation()
Vishant Shah    4.1         12/05/2017  removed updateOutboundRenewalCases and moved to SubscriptionHelper. Merged logic for Auto closing case as well.
**/
public with sharing class SubscriptionTriggerHandler extends SubscriptionHelper{

     // Boolean to control recursion
    public Boolean isExecuting = false;
    public Boolean bRunAPI = true;
    public Boolean bDeferredCalculationSkip = false;
    public Boolean bOcCaseUpdateSkip = false;

    private Map<String, Integer> productLeadDaysMap;
    private Boolean bSubscriptionChangeToPendingRunOnce = false;
    private static SubscriptionTriggerHandler instance;

    public static SubscriptionTriggerHandler getInstance() {
        if (instance == null) instance = new SubscriptionTriggerHandler();
        return instance;
    }

    public SubscriptionTriggerHandler(){
        super();
    }

    public void OnBeforeInsert(Subscription__c[] newSubscriptions){
         if (!this.isExecuting) {
            this.isExecuting = true;

            this.updateTextValues(newSubscriptions);
            this.setDefaultPlan(null, newSubscriptions);
            this.setupTCodeProductRelation(newSubscriptions);
            this.preventMultipleActiveSubs(null, newSubscriptions);
            this.populateTCodeForSchoolSubs(newSubscriptions);
            this.updateLowStartEndDate(null, newSubscriptions);
            this.validateAgainstProductPrice(null, newSubscriptions);
            this.isExecuting = false;
        }
    }

    public void OnAfterInsert(Subscription__c[] newSubscriptions){
        if (!this.isExecuting) {
            this.isExecuting = true;

            this.updateMPP_CurrentPayScheduleEndDateOnParentAccount(newSubscriptions, null);

            this.isExecuting = false;
        }
    }

    public void OnBeforeUpdate(Subscription__c[] oldSubscriptions, Subscription__c[] updatedSubscriptions, Map<ID, Subscription__c> OldSubscriptionMap, Map<ID, Subscription__c> NewSubscriptionMap){
        if (!this.isExecuting) {
            this.isExecuting = true;

            this.updateTextValues(updatedSubscriptions);
            this.setupTCodeProductRelation(updatedSubscriptions);
            this.preventMultipleActiveSubs(OldSubscriptionMap, updatedSubscriptions);
            this.updatesWhenProductChanged(OldSubscriptionMap, NewSubscriptionMap);
            this.handleRenewals(updatedSubscriptions, OldSubscriptionMap);
            this.startDateValidation(updatedSubscriptions, OldSubscriptionMap);
            this.updateLowStartEndDate(OldSubscriptionMap, updatedSubscriptions);
            this.checkProduct(updatedSubscriptions,OldSubscriptionMap);
            this.validateAgainstProductPrice(OldSubscriptionMap, updatedSubscriptions);
            this.isExecuting = false;
        }
        this.subscriptionInRenewalCreation(OldSubscriptionMap, updatedSubscriptions);
    }

    public void OnAfterUpdate(Subscription__c[] oldSubscriptions, Subscription__c[] updatedSubscriptions, Map<ID, Subscription__c> OldSubscriptionMap, Map<ID, Subscription__c> NewSubscriptionMap){
        if (!this.isExecuting) {
            this.isExecuting = true;

            this.handleCallDueTaskClosure(updatedSubscriptions, OldSubscriptionMap);
            this.updateMPP_CurrentPayScheduleEndDateOnParentAccount(updatedSubscriptions, OldSubscriptionMap);
            this.subscriptionChangeToPending(OldSubscriptionMap, updatedSubscriptions);

            if(this.bRunAPI){
                this.updateSamSubscriptionDetails(OldSubscriptionMap, updatedSubscriptions);
                this.subscriptionChangeToCancelled(OldSubscriptionMap, updatedSubscriptions);
            }

            this.deferredCalculation(OldSubscriptionMap, updatedSubscriptions); 
            autoCloseCases(OldSubscriptionMap, NewSubscriptionMap);

            this.isExecuting = false;
        }
    }

    public void OnBeforeDelete(Subscription__c[] SubscriptionsToDelete, Map<ID, Subscription__c> SubscriptionMap){}

    public void OnAfterDelete(Subscription__c[] deletedSubscriptions, Map<ID, Subscription__c> SubscriptionMap){}

    public void OnUndelete(Subscription__c[] restoredSubscriptions){
        if (!this.isExecuting) {
            this.isExecuting = true;
                 this.updateLowStartEndDate(null, restoredSubscriptions);
            this.isExecuting = false;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/09/2015
    Version - 1.0
    Function - Updates Low_Start_End_Date__c field on insert or on impacting fields changes (Start_Date__c, Low_Start_Period__c)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void updateLowStartEndDate(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){
        if(lstNew == null) return;
        Id lowStartType = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
        if(mapOld!=null){
            for(Subscription__c subscription : lstNew){
                Subscription__c old = mapOld.get(subscription.Id);
                if(subscription.RecordTypeId == lowStartType && subscription.Low_Start_Period__c != null && subscription.Start_Date__c != null && (subscription.Start_Date__c != old.Start_Date__c || subscription.Low_Start_Period__c != old.Low_Start_Period__c)){
                    subscription.Low_Start_End_Date__c = subscription.Start_Date__c.addDays(((Integer)subscription.Low_Start_Period__c) * 7  - 1);
                }
            }
        } else {
            for(Subscription__c subscription : lstNew){
                if(subscription.RecordTypeId == lowStartType && subscription.Low_Start_Period__c != null && subscription.Start_Date__c != null){
                    subscription.Low_Start_End_Date__c = subscription.Start_Date__c.addDays(((Integer)subscription.Low_Start_Period__c) * 7 - 1);
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 29/04/2016
    Version - 1.2
    Function - set Subscription field Plan__c with the default plan - based on Product definition or based on custom settings if former is not available
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/07/2016  //made sure default value is not populated if the value is there
    Wiktor Czykin   1.2         27/09/2016  //added support for product based default plan
	Pawel Chrzanowski 1.3       28/02/2017  //removed default plan for product switch
    ****************************************************************************************/
    private void setDefaultPlan(Map<Id, Subscription__c> mapOldSubscriptions, List<Subscription__c> lstNewSubscriptions){
        General__c defaultPlan = General__c.getInstance(Constants.DEFAULT_SUBSCRIPTION_PLAN);
        Id defaultSettingPlanId = null;
        if(defaultPlan != null && !String.isBlank(defaultPlan.Value__c)){
            try{
                defaultSettingPlanId = (Id) defaultPlan.Value__c;
            }catch(Exception e){}//silently fail if someone specifies invalid id value
        }

        List<Subscription__c> lstToProcess = new List<Subscription__c>();
		for(Subscription__c newSub : lstNewSubscriptions){
			if(newSub.Plan__c == null){
				lstToProcess.add(newSub);
			}
		}
		
        //find default plans based on related products
        Set<Id> setProductIds = new Set<Id>();
        for(Subscription__c sub : lstToProcess){
            if(sub.Product__c != null){
                setProductIds.add(sub.Product__c);
            }
        }
		
		Map<Id, zqu__ZProduct__c> mapProduct = new Map<Id, zqu__ZProduct__c>([select Id, Default_Plan__c from zqu__ZProduct__c where Id in :setProductIds and Default_Plan__c != null]);

        //assign default plans
        for(Subscription__c sub : lstToProcess){
            sub.Plan__c = defaultSettingPlanId;
            if(sub.Product__c != null){
                zqu__ZProduct__c zp = mapProduct.get(sub.Product__c);
                if(zp != null && zp.Default_Plan__c != null){
                    sub.Plan__c = zp.Default_Plan__c;
                }
            }
        }
    }

    /**
     * Added for PP-1731.
     * This method will take care of populating the TCode Management for School Subs being inserted
     *
     * @param newSubscriptions  the array of subscription objects being inserted
     */
    private void populateTCodeForSchoolSubs(Subscription__c[] newSubscriptions) {

        // fetch the SCHL TCode Management
        TCodeManagement__c schlTcodeMgmt = new TCodeManagement__c();
        try{
            schlTcodeMgmt = [select Id, Name from TCodeManagement__c where name = 'SCHL' limit 1];
        }catch(Exception ex){
            ex.getMessage();
        }
        for(Subscription__c newSub: newSubscriptions){
            if(newSub.RecordTypeId == TMGUtil.recordTypeMap.get('Subscription__c.Schools').Id) {
                if(schlTcodeMgmt != NULL)
                    newSub.TCode__c = schlTcodeMgmt.Id;
            }
        }
    }

    private void handleCallDueTaskClosure(List<Subscription__c> updatedSubscriptions, Map<Id, Subscription__c> OldSubscriptionMap) {
        if (Limits.getQueries() < Limits.getLimitQueries()) {
            Set<String> callOptions = new Set<String>
            {   'TL1 Call Due',
                'TL2 Call Due',
                'T2 Call Due',
                'T2 Call Due 28 Days'
            };
            Subscription__c tempOldSub = new Subscription__c();
            Set<Id> pendingSubsForTaskClosure = new Set<Id>();
            Set<Id> allSubsForTaskClosure = new Set<Id>();
            for (Subscription__c newSub : updatedSubscriptions) {
                tempOldSub = OldSubscriptionMap.get(newSub.Id);
                if (tempOldSub.Subscription_Status__c != newSub.Subscription_Status__c) {
                    if (tempOldSub.Subscription_Status__c == Constants.TSTATUS_OFFERED) {
                        if (newSub.Subscription_Status__c == Constants.SSTATUS_PENDING) {
                            pendingSubsForTaskClosure.add(newSub.Id);
                        }
                        allSubsForTaskClosure.add(newSub.Id);
                    }
                }
            }
            try {

                List<Task> tasksForClosure = [Select Subject, WhatId, WhoId from Task where WhatId in :allSubsForTaskClosure and Subject in :callOptions and Status != :Constants.TSTATUS_COMPLETED];

                for (Task taskForClosure : tasksForClosure) {
                    taskForClosure.Status = Constants.TSTATUS_COMPLETED;
                    taskForClosure.Outcome__c = Constants.TOUTCOME_AUTOCOMPLETED;
                    taskForClosure.OwnerId = Userinfo.getUserId();
                    taskForClosure.IsReminderSet = false;
                }

                Database.update(tasksForClosure, false);
            }
            catch(Exception ex) {
                System.debug('Problem closing Call due tasks');
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Send email to subsription related person account when status changes from offered to pending (for Online Subs)
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/02/2015  //logic moved here and ploughed from SubscriptionChangeToPending trigger so that trigger could be binned
    ****************************************************************************************/
    private void subscriptionChangeToPending(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){
        //as workflows are in place make sure email sending logic is called once
        if(this.bSubscriptionChangeToPendingRunOnce) return;
        this.bSubscriptionChangeToPendingRunOnce = true;

        Set<Id> setAccountIds = new Set<Id>();
        //only pending-payment taken and Web payments taken by WAC Replacement
        List<Subscription__c> lstSubscriptionsToProcess = new List<Subscription__c>();
        for (Subscription__c thissub : lstNew){
            if (    mapOld.get(thissub.Id).Subscription_Status__c == Constants.SSTATUS_OFFERED &&
                    thissub.Subscription_Status__c == Constants.SSTATUS_PENDING &&
                    thissub.Order_Taken_Method__c == 'Online Subs'
                ){

                setAccountIds.add(thissub.Subscriber__c);
                lstSubscriptionsToProcess.add(thissub);
            }
        }

        if (!setAccountIds.isEmpty()){
            Messaging.SingleEmailMessage emailMessage;

            Map<Id, Account> mapAccounts = new Map<Id, Account>([select     PersonContactId,
                                                                            PersonEmail,
                                                                            Salutation,
                                                                            FirstName,
                                                                            LastName,
                                                                            Subscriber_Number__c
                                                                        from Account
                                                                        where id In :setAccountIds
                                                                        and PersonContactId != null]);

            if (!mapAccounts.isEmpty()) {
                String sEmailIncentive = '';
                String sIncentiveHTML = '';

                Map<String, String> mapDefaults = new Map<String, String>();
                //for as previously there were multpiple records fetched. left as is for time being
                for(SubManagementDefaults__c smd : [select DefaultValue__c from SubManagementDefaults__c where ID__c ='EmailIncentive']){
                    mapDefaults.put(smd.Id__c, smd.DefaultValue__c);
                }

                if(mapDefaults.containsKey('EmailIncentive') && String.isNotBlank(mapDefaults.get('EmailIncentive'))){
                    sEmailIncentive = mapDefaults.get('EmailIncentive');
                }

                if (String.isNotBlank(sEmailIncentive)){
                    sIncentiveHTML = '<p>' + sEmailIncentive + '</p>';
                }
                List<Messaging.SingleEmailMessage> lstMessages = new List<Messaging.SingleEmailMessage>();

                for (Subscription__c thissub : lstSubscriptionsToProcess){
                    if(!mapAccounts.containsKey(thissub.Subscriber__c)) continue;

                        Account relatedAccount = mapAccounts.get(thissub.Subscriber__c);
                        //if (thissub.Subscription_Status__c == 'Pending' && subfilter.filterMapDigitalAndWebPack(Trigger.old).get(thissub.id).Subscription_Status__c == 'Offered'){
                        emailMessage = new Messaging.SingleEmailMessage();
                        emailMessage.setTargetObjectId(relatedAccount.PersonContactId);
                        emailMessage.setSaveAsActivity(false);
                        emailMessage.setReplyTo('customerservice@telegraph.co.uk');
                        emailMessage.setSenderDisplayName('The Telegraph');

                        String sPersonName = relatedAccount.Salutation + ' ' + relatedAccount.FirstName + ' ' + relatedAccount.LastName;

                        Datetime mytempdate = Datetime.valueOfgmt(thissub.Start_Date__c + 'T:00:00:00.000Z');
                        String sStartDate = String.valueof(mytempdate.format('dd/MM/yyyy'));
                        String sWeeklyPrice = String.valueof(thissub.Weekly_Price__c);
                        String sEmailSubNum = String.valueof(relatedAccount.Subscriber_Number__c);

                        emailMessage.setSubject('Telegraph Online Subscription');

                        if (thissub.Order_Taken_By_User_Department__c == 'POC'){ //a different email needs to be sent
                            emailMessage.setHtmlBody('<div id="header" style="padding-top: 10px"><IMG SRC="http://telegraph.force.com/OpenOffer/resource/1259074928000/WebRegImages/tele_masthead.png" BORDER="0" ALT="TMG logo"></div><p>&nbsp;</p>Dear ' + sPersonName + ',<p>&nbsp;</p>Thank you for subscribing to the Telegraph. Not only have you guaranteed yourself great savings on the cover price; but you will also start enjoying the benefits that come with a Telegraph subscription - including invitations to VIP events and exclusive subscriber offers.<p>&nbsp;</p>Your subscription start date is ' + sStartDate + ' at a weekly price of £' + sWeeklyPrice + '.<p>&nbsp;</p> Your first set of vouchers, together with your Welcome Pack, will arrive shortly in the post. Should you require any assistance with your subscription please click on our frequently asked questions section at <A href="http://www.telegraph.co.uk/sponsored/6515873/Subscriber-Frequently-Asked-Questions.html">F A Q</a>, contact our free customer service helpline on 0800 33 20 20, or alternatively you may email us at <A href="mailto:customerservice@telegraph.co.uk" target=_blank>customerservice@telegraph.co.uk</A> , please quote your Subscription Number <b>' + sEmailSubNum + '</b> in all correspondence.<p>&nbsp;&nbsp;</p><DIV style="TEXT-ALIGN: left">It’s great to welcome you as a <SPAN style="FONT-STYLE: italic">Telegraph </SPAN>subscriber<BR></DIV><BR><BR><DIV style="TEXT-ALIGN: left">Martin Harris<BR>Subscriptions Manager<BR>Telegraph Media Group <BR><DIV style="TEXT-ALIGN: left"><FONT size=1></FONT>&nbsp;</DIV><DIV style="TEXT-ALIGN: left"><FONT size=1>Should you require any assistance with your subscription, including details of how to unsubscribe, please visit our frequently asked questions section at <A href="http://www.telegraph.co.uk/sponsored/6515873/Subscriber-Frequently-Asked-Questions.html">F A Q</A></FONT></DIV><DIV style="TEXT-ALIGN: left"><FONT size=1><A href="http://www.telegraph.co.uk/substandc">Terms And Conditions</A>&nbsp;<FONT color=#008080 size=2><FONT color=#008080 size=2> <FONT size=1>Registered Address 111 Buckingham Palace Road, London, SW1W 0DT, Company Registration 451593</DIV></FONT></DIV></FONT></FONT></FONT>');
                        }else{
                            emailMessage.setHtmlBody('<div id="header" style="padding-top: 10px"><IMG SRC="http://telegraph.force.com/OpenOffer/resource/1259074928000/WebRegImages/tele_masthead.png" BORDER="0" ALT="TMG logo"></div><p>&nbsp;</p>Dear ' + sPersonName + ',<p>&nbsp;</p>Thank you for subscribing to the Telegraph. Not only have you guaranteed yourself great savings on the cover price; but you will also start enjoying the benefits that come with a Telegraph subscription - including invitations to VIP events and exclusive subscriber offers.<p>&nbsp;</p>Your subscription start date is ' + sStartDate + ' at a weekly price of £' + sWeeklyPrice + '.<p>&nbsp;</p> Your first set of vouchers, together with your Welcome Pack, will arrive shortly in the post. Should you require any assistance with your subscription please click on our frequently asked questions section at <A href="http://www.telegraph.co.uk/sponsored/6515873/Subscriber-Frequently-Asked-Questions.html">F A Q</a>, contact our free customer service helpline on 0800 33 20 20, or alternatively you may email us at <A href="mailto:customerservice@telegraph.co.uk" target=_blank>customerservice@telegraph.co.uk</A> , please quote your Subscription Number <b>' + sEmailSubNum + '</b> in all correspondence.<p>&nbsp;&nbsp;</p><DIV style="TEXT-ALIGN: left">' + sIncentiveHTML + 'It’s great to welcome you as a <SPAN style="FONT-STYLE: italic">Telegraph </SPAN>subscriber<BR></DIV><BR><BR><DIV style="TEXT-ALIGN: left">Martin Harris<BR>Subscriptions Manager<BR>Telegraph Media Group <BR><DIV style="TEXT-ALIGN: left"><FONT size=1></FONT>&nbsp;</DIV><DIV style="TEXT-ALIGN: left"><FONT size=1>Should you require any assistance with your subscription, including details of how to unsubscribe, please visit our frequently asked questions section at <A href="http://www.telegraph.co.uk/sponsored/6515873/Subscriber-Frequently-Asked-Questions.html">F A Q</A></FONT></DIV><DIV style="TEXT-ALIGN: left"><FONT size=1><A href="http://www.telegraph.co.uk/substandc">Terms And Conditions</A>&nbsp;<FONT color=#008080 size=2><FONT color=#008080 size=2> <FONT size=1>Registered Address 111 Buckingham Palace Road, London, SW1W 0DT, Company Registration 451593</DIV></FONT></DIV></FONT></FONT></FONT>');
                        }
                        lstMessages.add(emailMessage);

                        //}
                }
                if(!lstMessages.isEmpty()){
                    Messaging.sendEmail(lstMessages, false);
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function -  When a Subscription record status is changed to 'In Renewal' create a new Subscription record with status 'Offered' and  fields populated from the current 'In Renewal' Subscription
                Calls subscriptionInRenewalCreation class to create a new 'Offered' subscription with fields populated with values from the current active subscription.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/02/2015  //logic moved here from subscriptionInRenewal trigger and subscriptionInRenewalTrigger class so that extra trigger and one helper could be binned
    Wiktor Czykin   1.2         30/07/2015  //replaced lock flag with bDeferredCalculationSkip
    Michal Szewczyk 1.3         13/06/2016  //added error message to exception throw
    ****************************************************************************************/
    private void subscriptionInRenewalCreation(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){
        System.debug('subscriptionInRenewal function: skip is '+ this.bDeferredCalculationSkip);
        if (DeferredCalculation.inDeferredCalc == null) {DeferredCalculation.inDeferredCalc = false;}

        // for deferred rev calc
        Boolean wasFalse = false;
        if (!DeferredCalculation.inDeferredCalc) {
            wasFalse = true;
            DeferredCalculation.inDeferredCalc = true;
        }

        //Check lock to prevent recursive trigger action
        if(this.bDeferredCalculationSkip) {
            if (wasFalse) {DeferredCalculation.inDeferredCalc = false;}
            return;
        }
        //set lock in case other subscriptions are updated by this trigger
        this.bDeferredCalculationSkip = true;

        try{
            Map<ID, Subscription__c> inrenewalSubs = new Map<ID, Subscription__c>();
            //Check if subscription status has become 'In Renewal'
            for(Subscription__c sub : lstNew){
                if(sub.Subscription_Status__c == Constants.SSTATUS_IN_RENEWAL && mapOld.get(sub.Id).Subscription_Status__c != Constants.SSTATUS_IN_RENEWAL){
                    inrenewalSubs.put(sub.Id, sub);
                }
            }

            //Create new 'Offered' subscriptions for all 'In Renewal' subscriptions
            if(!inrenewalSubs.isEmpty()){
                //create new subscriptions array by calling the creation class
                subscriptionInRenewalCreation.handleRenewedSubscriptions(inrenewalSubs, 'trigger');
            }
        } catch (Exception e) {
            for(Subscription__c sub : lstNew) {
                sub.addError('Error processing subscription an exception was thrown: ' + e.getMessage());
                System.debug('subscriptionInRenewalTrigger: Exception thrown trying to process '+sub+'\'In Renewal\' subscritpion in an after update trigger ' + e);
            }
        }

        //Leave the lock on as workflow causes this trigger to fire again which we need to prevent
        if (wasFalse) {DeferredCalculation.inDeferredCalc = false;}
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  prevents a subsciber having more than one active subscription at a time.
                When a new active subscription is inserted for a subscriber, or an existing offered subscription
                becomes active, the trigger checks that the new subscription start date does not occur before
                the end date of a subscribers existing active subscription. A subscription is deemed to be active if it has a status of
                either 'Active', 'In Renewal', 'Pending', 'Pending Cancellation' or 'Temporary Suspension'.
                If a subscribers current subscription status is 'Pending Cancellation' then the 'cancellation
                date' is used as its end date.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/02/2015  //logic moved here from SubscriptionToPreventMultipleActiveSubs trigger so that the extra trigger could be binned
                                            //it is not most efficient method but I'm not modifying it
    ****************************************************************************************/
    private void preventMultipleActiveSubs(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){

        try{
            //Generate a list of subscriptions requiring a check for an existing overlapping active subscription
            List<Subscription__c> subsToCheck = new List<Subscription__c>{};
            //If is an insert operation then all subscriptions being inserted need to be checked for an overlapping active sub

            //Define a list of status' that constitute an 'Active' subscription
            Set<String> setApplicableStatuses = new Set<String>{Constants.SSTATUS_ACTIVE, Constants.SSTATUS_IN_RENEWAL, Constants.SSTATUS_PENDING, Constants.SSTATUS_PENDING_CANX, Constants.SSTATUS_TEMP_SUSPENSION};
            if(mapOld == null && lstNew != null){
                subsToCheck = lstNew;
            } else if (mapOld != null && lstNew != null) {
                //If is an update we only need check Offered subscriptions that have now become active

                for(Subscription__c subs : lstNew){
                    if(mapOld.get(subs.Id).Subscription_Status__c == 'Offered' && setApplicableStatuses.contains(subs.Subscription_Status__c)){
                        subsToCheck.add(subs);
                    }
                }
            }

            Boolean existingActiveSubFound;

            //obtain a list of subscriber IDs for whom the new subscription is being generated
            Set<Id> setSubscribers = new Set<Id>{};
            for(Subscription__c sub: subsToCheck) {
                setSubscribers.add(sub.Subscriber__c);
            }

            //return all active subscriptions for each subscriber
            List<Subscription__c> activeSubscriptions = [select Subscription_Status__c,
                                                                Subscriber__c,
                                                                End_Date__c,
                                                                Cancellation_Date__c
                                                            from Subscription__c
                                                            where Subscriber__c in :setSubscribers
                                                            and Subscription_Status__c in :setApplicableStatuses
                                                            limit 1000];

            //check if subscriber already has an active subscription covering the start date of the new subscription being inserted
            for(Subscription__c subTocheck : subsToCheck){
                existingActiveSubFound = false;
                for(Subscription__c existingSubs: activeSubscriptions){
                    if(existingSubs.Subscriber__c == subTocheck.Subscriber__c){
                        if(subTocheck.Start_Date__c <= existingSubs.Cancellation_Date__c && existingSubs.Subscription_Status__c == Constants.SSTATUS_PENDING_CANX && subTocheck.Id != existingSubs.Id){
                            existingActiveSubFound = true;
                        } else if(subTocheck.Start_Date__c <= existingSubs.End_Date__c && existingSubs.Subscription_Status__c != Constants.SSTATUS_PENDING_CANX && subTocheck.id!=existingSubs.id){
                            existingActiveSubFound = true;
                        }
                    }
                    if(existingActiveSubFound){
                        subTocheck.Start_Date__c.addError('Subscription cannot be saved with this start date. The subscriber already has an Active subscription covering all or part of this time period');
                        break;
                    }
                }
            }
        } catch (Exception exc) {
            for(Subscription__c sub : lstNew) {
                sub.addError('Error checking for conflicting active subscriptions, an exception was thrown');
                System.debug('SubscriptionToPreventMultipleActiveSubs: Exception thrown when checking for any conflicting active subscriptions. Error recieved:  ' + exc);
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.6
    Function -  updates SAM with account details -> on status change when mpp callout stage is not changed
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/02/2015  //logic moved here from UpdateSamSubscriptionDetails trigger so that the extra trigger could be binned
    Wiktor Czykin   1.2         30/03/2015  //modified sam single update target method as the previous helper class was replaced
    Crstina Popescu 1.3         10/06/2015  //update method to sync account with SAM only if it has an email address
    Wiktor Czykin   1.4         24/06/2015  //removed custom settings dependency as could cause potential stop to SAM updates across the org
    Michal Szewczyk 1.5         28/04/2016  //replaced callSamForSingleUpdate with callSamForUpdateAsync for one rec
    Wiktor Czykin   1.6         31/01/2017  //modified callSamForUpdateAsync() method signature
    ****************************************************************************************/
    private void updateSamSubscriptionDetails(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){
        System.debug('This trigger has already fired: '+SubscriberPortal.SUB_TRIGGER_FIRED);
        set<Id> accountsWithEmail = new set<Id>();
        if(!SubscriberPortal.SUB_TRIGGER_FIRED){
            Set<Id> accIds = new Set<Id>();
            for(Subscription__c newSub : lstNew){
                Subscription__c oldSub = mapOld.get(newSub.Id);
                //MIrfan@Appirio, Plane 1.2, ByPass calling SAM for DD Migration Batch. 130612
                if(newSub.Subscription_Status__c <> oldSub.Subscription_Status__c && newSub.MppDDCalloutStage__c == oldSub.MppDDCalloutStage__c){
                    accIds.add(newSub.Subscriber__c);
                }
            }
            //select only the accounts that have an email to be synced with SAM
            for (Account acc : [SELECT Id,PersonEmail FROM Account WHERE Id IN: accIds AND PersonEmail!=null]){
                accountsWithEmail.add(acc.Id);
            }

            // Don't make the outbound call if there are no matching accounts, or if the trigger has fired already in this transaction
            if (!accIds.isEmpty()) {
                SubscriberPortal.SUB_TRIGGER_FIRED = true;

                    if(!accountsWithEmail.isEmpty()){
                        if(accIds.size() > 1 ){
                            if((Label.ByPassSamUpdatesForUser == null || Label.ByPassSamUpdatesForUser != UserInfo.getUserName()) && (Label.SamUserId == null || Label.SamUserId != UserInfo.getUserName())){
                                UpdateSamUserDetailsBatch.callSamForUpdateAsync(accountsWithEmail, true, false);
                             }
                        } else{
                             UpdateSamUserDetailsBatch.callSamForUpdateAsync(accountsWithEmail, true, false);
                        }
                   }

            }
        }
        System.debug('*** End of UpdateSamSubscriptionDetails ***');
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Setting of Cur_Week_Pos_Final_Text_Hidden__c and Sub_Status_Not_Started_Text_Hidden__c fields
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/02/2015  //logic moved here from Subscription_beforeInsUpd_UpdTextValues trigger so that the extra trigger could be binned
    ****************************************************************************************/
    private void updateTextValues(List<Subscription__c> lstNew){
        Set<String> setInactiveStatuses = new Set<String>{  Constants.SSTATUS_OFFERED,
                                                            Constants.SSTATUS_PENDING,
                                                            Constants.SSTATUS_WITHDRAWN,
                                                            Constants.SSTATUS_DECLINED,
                                                            Constants.SSTATUS_CANX };
        for (Subscription__c s : lstNew) {
            //current week position final
            if (s.Current_Week_Position_Final__c != null) {
                if (s.Cur_Week_Pos_Final_Text_Hidden__c == null){
                    s.Cur_Week_Pos_Final_Text_Hidden__c = '';
                }
                if (String.valueOf(s.Current_Week_Position_Final__c.intValue()) != s.Cur_Week_Pos_Final_Text_Hidden__c){
                    s.Cur_Week_Pos_Final_Text_Hidden__c = String.valueOf(s.Current_Week_Position_Final__c.intValue());
                }
            } else {
                s.Cur_Week_Pos_Final_Text_Hidden__c = null;
            }

            // sub status
            if (setInactiveStatuses.contains(s.Subscription_Status__c)){
                s.Sub_Status_Not_Started_Text_Hidden__c = 'Not Active';
            } else {
                s.Sub_Status_Not_Started_Text_Hidden__c = 'Active';
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function -  calls DefferedCalculation helper to count payment and voucher sums
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         05/03/2015  //logic moved here and cleaned up a bit from Subscription_afterInsUpd_deferredCalcs trigger so that the extra trigger could be binned
    Wiktor Czykin   1.2         18/06/2015  //modified the way the DeferredCalculation is populated with subscription records
    ****************************************************************************************/
    private void deferredCalculation(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){
        if (DeferredCalculation.isTestScenario == null) {DeferredCalculation.isTestScenario = false;}
        if (DeferredCalculation.inDeferredCalc == null) {DeferredCalculation.inDeferredCalc = false;}

        if (!DeferredCalculation.isTestScenario && !DeferredCalculation.inDeferredCalc) {
            DeferredCalculation.inDeferredCalc = true;

            DeferredCalculation.DeferredVoucherCalc calc = new DeferredCalculation.DeferredVoucherCalc();
            Set<Id> setSubsForProcessing = new Set<Id>();
            for (Subscription__c sub : lstNew) {
                if (sub.Deferred_Calc_Force_Update__c && !mapOld.get(sub.Id).Deferred_Calc_Force_Update__c) {
                    setSubsForProcessing.add(sub.Id);
                }
            }
            if (!setSubsForProcessing.isEmpty()) {
                calc.addSubsForProcessing(setSubsForProcessing);
                calc.GetSubData();
                calc.Calculate();
                calc.UpdateValues();

                //update the force update flag to false
                List<Subscription__c> lstToUpdate = new List<Subscription__c>();
                for (Id subId : setSubsForProcessing) {
                    lstToUpdate.add(new Subscription__c(Id = subId, Deferred_Calc_Force_Update__c = false));
                }
                try {
                   update lstToUpdate;
                } catch (Exception e) {
                    for(Subscription__c s : lstNew){
                        if(setSubsForProcessing.contains(s.Id)){
                            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, 'Error in update of force flag:'+e));
                        }
                    }
                }
            }
            DeferredCalculation.inDeferredCalc = false;
        }
    }


    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function -
    //this trigger action needs fixing as adding duplicate Accounts to list for update
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/02/2015  //added SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE flag to enable/disable feature, added Constants, added check if numeric
    Wiktor Czykin   1.2         01/05/2015  //made this method actually bulk safe, only updates MPP_CurrentPayScheduleEndDate__c if subscription MPP_Pay_Schedule_End_Date__c exists
    ****************************************************************************************/
    private void updateMPP_CurrentPayScheduleEndDateOnParentAccount(Subscription__c[] newSubs, Map<Id, Subscription__c> oldSubs){

        Set<Id> setAccountIds = new Set<Id>();
        List<Subscription__c> lstForFurtherProcessing = new List<Subscription__c>();

        for(Subscription__c newSub : newSubs){
            if(newSub.Subscriber__c == null) continue;

            if(oldSubs == null){ //INSERT,  no old data
                if(newSub.Subscription_Status__c == Constants.SSTATUS_PENDING || newSub.Subscription_Status__c == Constants.SSTATUS_ACTIVE){
                    setAccountIds.add(newSub.Subscriber__c);
                    lstForFurtherProcessing.add(newSub);
                }
            }else{ //UPDATE
                Subscription__c oldSub = oldSubs.get(newSub.Id);
                if(oldSub != null && oldSub.Subscription_Status__c != newSub.Subscription_Status__c && (newSub.Subscription_Status__c == Constants.SSTATUS_PENDING || newSub.Subscription_Status__c == Constants.SSTATUS_ACTIVE)){
                    setAccountIds.add(newSub.Subscriber__c);
                    lstForFurtherProcessing.add(newSub);
                }
            }
        }

        //We have newly pending or active subscriptions,  update the parent account
        if(!lstForFurtherProcessing.isEmpty()){
            Map<Id, Date> mapAccountIdToDate = new Map<Id, Date>();
            Map<Id, Account> mapPotentialAccountsToUpdate = new Map<Id, Account>([select    Id,
                                                                                            MPP_CurrentPayScheduleEndDate__c
                                                                                        from Account
                                                                                        where Id in :setAccountIds]);
            if(mapPotentialAccountsToUpdate.isEmpty()) return;
            for(Subscription__c sub : lstForFurtherProcessing){
                if(!mapPotentialAccountsToUpdate.containsKey(sub.Subscriber__c)) continue;

                if( sub.MPP_Pay_Schedule_End_Date__c != null &&
                    mapPotentialAccountsToUpdate.get(sub.Subscriber__c).MPP_CurrentPayScheduleEndDate__c != sub.MPP_Pay_Schedule_End_Date__c.date()
                   ){
                        mapAccountIdToDate.put(sub.Subscriber__c, sub.MPP_Pay_Schedule_End_Date__c.date());
                }
            }

            if(!mapAccountIdToDate.isEmpty()){
                List<Account> lstAccountsToUpdate = new List<Account>();
                for(Id accId : mapAccountIdToDate.keySet()){
                    lstAccountsToUpdate.add(new Account(Id = accId, MPP_CurrentPayScheduleEndDate__c = mapAccountIdToDate.get(accId)));
                }
                if(!lstAccountsToUpdate.isEmpty()){
                    update lstAccountsToUpdate;
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 08/06/2015
    Version - 1.1
    Function -  Method to be run on before update.
                Logic is executed for 23 days renewals, when subscription status is not changed and Pending and start date is modified.
                Then depending on the previous Next_Vocher_Extraction__c(which is based partially on Start_Date__c) it modified Is_Fast_Track__c flag.
                The lower limit for the modification is checked via standard validation rules, so not adding
                those checks here (Start_Date_Second_Monday_Future and Start_Date_Second_Monday_Future_Renewal validation rules).
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         15/06/2015  //added time validation when Start Date is changed to the previous version extraction date
    Wiktor Czykin	1.2			08/11/2015	//made public
    Vishant Shah    1.3         09/02/2017  //code improvments to reduce soql queries in execution
    ****************************************************************************************/
    public void startDateValidation(List<Subscription__c> lstNew,  Map<Id, Subscription__c> mapOldSubscriptions){
        if(lstNew == null || mapOldSubscriptions == null) return;

        General__c renewalsHandling = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE);
        General__c cutOff = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_CUTOFF);
        General__c leadTime = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);

        Integer firstClassCutoffDate;
        Integer firstClassLeadTime;

        if(cutOff != null && String.isNotBlank(cutOff.Value__c) && cutOff.Value__c.isNumeric()){
            firstClassCutoffDate = Integer.valueOf(cutOff.Value__c);
        }

        if(leadTime != null && String.isNotBlank(leadTime.Value__c) && leadTime.Value__c.isNumeric()){
            firstClassLeadTime = Integer.valueOf(leadTime.Value__c);
        }
        if(renewalsHandling == null || !renewalsHandling.Value_Boolean__c || firstClassCutoffDate == null || firstClassLeadTime == null) return;

        Boolean bApplicable = true;
        General__c profiles = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
        if(profiles != null && String.isNotBlank(profiles.Value__c)){
            try{
                List<String> lstSplit = profiles.Value__c.split(Constants.SUBSCRIPTION_STARTDATEVALIDATION_SPLIT);
                for (String profileName : lstSplit){
                    if (UserInfo.getProfileId() == Constants.getProfileIdByName(profileName)){
                        bApplicable = false;
                    }  
                }
            }catch(Exception e){
                System.debug('fail silently');
            }
        }

        Boolean bExtractTimeCheck = DateUtility.isBeforeExtractionTime();

        Map<Id, Subscription__c> mapForVerification = new Map<Id, Subscription__c>();
        Time t = Datetime.now().time();
        for(Subscription__c sub : lstNew){
            Subscription__c old = mapOldSubscriptions.get(sub.Id);
            if( sub.Subscription_Status__c == Constants.SSTATUS_PENDING &&
                sub.Subscription_Status__c == old.Subscription_Status__c &&
                sub.Start_Date__c != null && sub.Start_Date__c != old.Start_Date__c){


                if(bApplicable && (Date.today() > old.Next_Voucher_Extraction__c || (Date.today() == old.Next_Voucher_Extraction__c && !bExtractTimeCheck))){
                    sub.addError(Label.X23_days_renewal_cannot_change_start_date_after_extraction);
                }else{
                   mapForVerification.put(sub.Id, sub);
                }
            }
        }

        if(mapForVerification.isEmpty()) return;

        Date closestSaturday = DateUtility.getDateOfNextNamedDay(Date.today(), 'Saturday'); //but next Saturday if today is Saturday
        for(Subscription__c sub : mapForVerification.values()){
            //not checking 9 days time span as it is checked by standard validation rule
            if(sub.Previous_Subscription__c != null && (Math.abs(sub.Start_Date__c.daysBetween(closestSaturday)) < firstClassCutoffDate)){
                sub.Is_Fast_Track__c  = true;
            }else{
                sub.Is_Fast_Track__c = false;
            }
        }
    }

    /***************************************************************************************
    Developer - Matt Hime (Tquila)
    Date - Unknown
    Version - 1.2
    Function - sets Is_Fast_Track__c flag and updates Start_Date__c if required
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/02/2015  //added SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE flag to enable/disable feature, added Constants, added check if numeric
    Wiktor Czykin   1.2         05/06/2015  //removed setting of Next_Voucher_Extraction_Override__c field value
    Vishant Shah    1.3         18/01/2017  //logic for LeadDays from zProduct
    ****************************************************************************************/
    private void handleRenewals(Subscription__c[] updatedSubscriptions, Map<Id, Subscription__c> oldSubscriptions){
        //Check the custom settings are populated before proceding.  This is primarily for test class reasons,  there are far too many historic test classes for me to trawl through
        //and ensure that the data is set up correctly.  If it's not here,  do none of the work!
        General__c renewalsHandling = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE);
        if(renewalsHandling == null || !renewalsHandling.Value_Boolean__c){
            return;
        }

        General__c generalData = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_CUTOFF);
        Integer firstClassCutoffDate;
        if(generalData != null && String.isNotBlank(generalData.Value__c) && generalData.Value__c.isNumeric()){
            firstClassCutoffDate = Integer.valueOf(generalData.Value__c);
        }

        //Get the minimum number of days First Class mail needs to arrive
        generalData = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        Integer firstClassLeadTime;
        if(generalData != null && String.isNotBlank(generalData.Value__c) && generalData.Value__c.isNumeric()){
            firstClassLeadTime = Integer.valueOf(generalData.Value__c);
        }

        if(firstClassCutoffDate != null && firstClassLeadTime != null){

            for(Subscription__c updatedSub : updatedSubscriptions){
                Subscription__c oldSub = oldSubscriptions.get(updatedSub.Id);

                if (productLeadDaysMap != null && productLeadDaysMap.get(updatedSub.Product__c) != null){
                    firstClassLeadTime = productLeadDaysMap.get(updatedSub.Product__c);
                }

                //If this is a renewed subscription that has moved to pending
                if(updatedSub.Subscription_Status__c == Constants.SSTATUS_PENDING && oldSub.Subscription_Status__c == Constants.SSTATUS_OFFERED
                    && updatedSub.if_Is_Renewal_Binary__c == 1){

                    Date renewalDate = Date.today(); //This may not be the right date to use,  run with it for now
                    //Renewal day is always a Saturday,  so,  adjust
                    Date saturdayAdjustedRenewalDate = DateUtility.getDateOfNextNamedDay(renewalDate, 'Saturday');

                    //Is there enough time to send this third class?
                    if((Math.abs(updatedSub.Start_Date__c.daysBetween(saturdayAdjustedRenewalDate)) < firstClassCutoffDate) || updatedSub.Start_Date__c < saturdayAdjustedRenewalDate){
                        updatedSub.Is_Fast_Track__c = true;

                        //Recalculate the start date accounting for the minimum number of days need for 1st class mail and the fact that it's always a Monday
                        Date newStartDate = saturdayAdjustedRenewalDate.addDays(firstClassLeadTime);
                        if(DateUtility.DayOfWeek(newStartDate) != 'Monday'){
                            newStartDate = DateUtility.getDateOfNextNamedDay(newStartDate, 'Monday');
                        }

                        //If the recalculated start date is after the expected start date use it instead of
                        if(newStartDate > updatedSub.Start_Date__c){
                            updatedSub.Start_Date__c = newStartDate;
                        }
                    } else{
                        updatedSub.Is_Fast_Track__c = false;
                    }
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 23/02/2015
    Version - 1.0
    Function - mostly copy paste of logic from Matt's handleRenewals() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Date findNextStartDate(Subscription__c subscription){
        if(subscription == null || subscription.Start_Date__c == null) return null;

        General__c renewalsHandling = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE);
        if(renewalsHandling == null || !renewalsHandling.Value_Boolean__c){
            return null;
        }

        General__c generalData = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_CUTOFF);
        Integer firstClassCutoffDate;
        if(generalData != null && String.isNotBlank(generalData.Value__c) && generalData.Value__c.isNumeric()){
            firstClassCutoffDate = Integer.valueOf(generalData.Value__c);
        }

        generalData = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        Integer firstClassLeadTime;
        if(generalData != null && String.isNotBlank(generalData.Value__c) && generalData.Value__c.isNumeric()){
            firstClassLeadTime = Integer.valueOf(generalData.Value__c);
        }

        if(firstClassCutoffDate != null && firstClassLeadTime != null && subscription.if_Is_Renewal_Binary__c == 1){
            Date renewalDate = Date.today();
            Date saturdayAdjustedRenewalDate = DateUtility.getDateOfNextNamedDay(renewalDate, 'Saturday');
            if((Math.abs(subscription.Start_Date__c.daysBetween(saturdayAdjustedRenewalDate)) < firstClassCutoffDate) || subscription.Start_Date__c < saturdayAdjustedRenewalDate){
                //Recalculate the start date accounting for the minimum number of days need for 1st class mail and the fact that it's always a Monday
                Date nextStartDate = saturdayAdjustedRenewalDate.addDays(firstClassLeadTime);
                if(DateUtility.DayOfWeek(nextStartDate) != 'Monday'){
                    nextStartDate = DateUtility.getDateOfNextNamedDay(nextStartDate, 'Monday');
                }
                return nextStartDate;
            }else return subscription.Start_Date__c;
        }
        return null;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie
    Date - 11/09/2015
    Version - 1.1
    Function - Cancel MPP Payment Schedule when subscription status is set to CANCELLED
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.2         24/09/2015  //change logic to cancel payment schedules when status is moved to pending cancellation
    ****************************************************************************************/
    private void subscriptionChangeToCancelled(Map<Id, Subscription__c> mapOld, List<Subscription__c> lstNew){
        //only cancelled subs should be considered
        String mppSubIDs;
        for (Subscription__c sub : lstNew){
            if (mapOld.get(sub.Id).Subscription_Status__c != sub.Subscription_Status__c &&
                sub.Subscription_Status__c == Constants.SSTATUS_PENDING_CANX){
                mppSubIDs = sub.MPP_Premium_Subscription_ID__c;
                break;
            }
        }
        if (String.isNotBlank(mppSubIDs)){
            try{
                //call webservice method to cancel sub payment schedules
                MPPInterfaceHTTP.invokeSinglePaymentScheduleCancellation(mppSubIDs);
            } catch (Exception e) {
                for(Subscription__c sub : lstNew) {
                    sub.addError('Cancellation of MPP Payment Schedules Failed');
                    System.debug('Cancellation of MPP Payment Schedules Failed: Exception thrown trying to process '+sub+'\'Cancelled\' subscription in an after update trigger ' + e);
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 21/03/2016
    Version 1.2
    Function - set up Subscription -> TCodeProduct lookup relation
    #############Change Log#############
    Modified by         Version     Change Date
    Vishant Shah        1.1         18/01/2017  Added productLeadDaysMap
    Wiktor Czykin       1.2         02/03/2017  Added Record Type filter for TCode Product soql
    ****************************************************************************************/
    private void setupTCodeProductRelation(List<Subscription__c> lstNew){
        Set<Id> tCodeManagementIdSet                              = new Set<Id>();
        Set<Id> productIdSet                                      = new Set<Id>();
        Map<String, Subscription__c> subTcodeManagementProductMap = new Map<String, Subscription__c>();
        List<TCode_Product__c> lstTcodeProducts                   = new List<TCode_Product__c>();
        productLeadDaysMap                                        = new Map<String, Integer>();

        if(!lstNew.isEmpty()){
            for(Subscription__c sub : lstNew){
                if(sub.TCode__c != null && sub.Product__c != null){
                    tCodeManagementIdSet.add(sub.TCode__c);
                    productIdSet.add(sub.Product__c);
                    subTcodeManagementProductMap.put(String.valueOf(sub.TCode__c) + ',' + String.valueOf(sub.Product__c), sub);
                }
            }
        }

        if(!tCodeManagementIdSet.isEmpty() && !productIdSet.isEmpty()) {
            Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
            lstTcodeProducts = [select TCodeManagement__c, Product__c, Product__r.LeadDays__c  from TCode_Product__c where TCodeManagement__c in :tCodeManagementIdSet and Product__c in :productIdSet and RecordTypeId = :offerRecordTypeId];
        }
        
        if(!lstTcodeProducts.isEmpty()){
            for(TCode_Product__c tcp : lstTcodeProducts){
                String key = String.valueOf(tcp.TCodeManagement__c) + ',' + String.valueOf(tcp.Product__c);
                if(subTcodeManagementProductMap.containsKey(key)){
                    subTcodeManagementProductMap.get(key).TCode_Product__c = tcp.Id;
                }

                if (!productLeadDaysMap.containsKey(tcp.Product__c) && tcp.Product__r.LeadDays__c != null){
                    productLeadDaysMap.put(tcp.Product__c, Integer.valueOf(tcp.Product__r.LeadDays__c));
                }
            }
        }
    }
    /**
    * Developer Michal Szewczyk
    * Date 14/06/2016
    * Function  validate the product was not blanking out
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    private void checkProduct(List<Subscription__c> newSubscriptions,Map<Id, Subscription__c> mapOld){

        for(Subscription__c sub: newSubscriptions) {
            if(sub.Product__c == null && mapOld.get(sub.Id).Product__c != null) {
                sub.addError(Label.Subscriptions_Product_Missing);
            }
        }
    }
    /**
    * Developer Gavin Palmer
    * Date 27/05/2016
    * Function  validate the fields against the product price table
    *#############Change Log#############
    *Modified by     Version     Change Date
    Michal Szewczyk 21/06/2016  //exclude subs without product from processed subs
    Wiktor Czykin   18/09/2016  //modified logic so that old records are send as well 
    **/
    private void validateAgainstProductPrice(Map<Id, Subscription__c> mapOldSubscriptions, List<Subscription__c> lstNewSubscriptions){
        List<Subscription__c> validatedSubs = new List<Subscription__c>();
        List<Subscription__c> oldValidatedSubs;
        for(Subscription__c sub: lstNewSubscriptions){
            if(sub.Product__c != null) {
                validatedSubs.add(sub);
            }
        }
        if(mapOldSubscriptions != null){
            oldValidatedSubs = new List<Subscription__c>();
            for(Subscription__c s : validatedSubs){
                oldValidatedSubs.add(mapOldSubscriptions.get(s.Id));
            }
        }
        List<TMGUtil.FieldValidationWrapper> fieldsToValidate = new List<TMGUtil.FieldValidationWrapper>{
            new TMGUtil.FieldValidationWrapper(
                'Weekly_Price__c',
                Label.Subscription_Weekly_Price_Validation,
                new Map<Boolean, String>{
                    true => Constants.PRODUCT_PRICE_RENEWAL,
                    false => Constants.PRODUCT_PRICE_AQUISITION
                },
                'Is_Renewal__c',
                Constants.PRODUCT_PRICE_RENEWAL
            ),
            new TMGUtil.FieldValidationWrapper(
                'Renewal_Price_Override__c',
                Label.Subscription_Renewal_Price_Validation,
                Constants.PRODUCT_PRICE_RENEWAL
            ),
            new TMGUtil.FieldValidationWrapper(
                'Low_Start_Weekly_Price__c',
                Label.Subscription_Low_Start_Validation,
                Constants.PRODUCT_PRICE_AQUISITION
            )
        };
        if(validatedSubs.size() > 0) {
            TMGUtil.validateAgainstProductPrice(validatedSubs, oldValidatedSubs, fieldsToValidate, 'Product__c');
        }
    }
    
    /**
    * Developer: Vishant Shah
    * Date: 18/01/2017
    * Description: Method to update start date when product changes
    * #############Change Log#############
    * Modified by       Version     Change Date
    **/
    private void updatesWhenProductChanged(Map<Id,Subscription__c> oldSubscriptionMap, Map<Id,Subscription__c> newSubscriptionMap){

        Set<Id> accountsWithEmail = new Set<Id>();
        
        General__c generalData    = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_CUTOFF);
        Integer firstClassCutoffDate;
        if(generalData != null && String.isNotBlank(generalData.Value__c) && generalData.Value__c.isNumeric()){
            firstClassCutoffDate = Integer.valueOf(generalData.Value__c);
        } 

        Integer firstClassLeadTime;
        generalData = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        if(generalData != null && String.isNotBlank(generalData.Value__c) && generalData.Value__c.isNumeric()){
            firstClassLeadTime = Integer.valueOf(generalData.Value__c);
        }

        if (firstClassLeadTime != null && this.bRunAPI){
            
            Map<Id, zqu__ZProduct__c> productMap = new Map<Id, zqu__ZProduct__c>([SELECT Id, Name, Print_Product__c,
                                                                                    (SELECT ZProduct__c, UpgradeProduct__c, ProductName__c, UpgradeProductName__c FROM MidTermUpgradeProducts__r) 
                                                                                   FROM zqu__ZProduct__c]);
            Set<Id> subsAllowedForProductChange = new Set<Id>();

            for (Subscription__c oldSub : oldSubscriptionMap.values() ){

                Subscription__c newSub         = newSubscriptionMap.get(oldSub.Id);
                Boolean subProductChanged      = oldSub.Product__c != newSub.Product__c; 
                Boolean isProductChangeAllowed = false;
                String subStatus               = newSub.Subscription_Status__c;
                Set<String> allowedStatus      = new Set<String>{ Constants.SSTATUS_ACTIVE, 
                                                                  Constants.SSTATUS_PENDING_CANX, 
                                                                  Constants.SSTATUS_IN_RENEWAL };

                if (!productMap.isEmpty() && newSub.Product__c != null && productMap.get(oldSub.Product__c) != null && productMap.get(oldSub.Product__c).MidTermUpgradeProducts__r != null){

                    for (MidTermUpgradeProduct__c upgradeProduct : productMap.get(oldSub.Product__c).MidTermUpgradeProducts__r){
                        if (newSub.Product__c == upgradeProduct.UpgradeProduct__c){
                            isProductChangeAllowed = true;
                            break;
                        }
                    }
                
                    if (subProductChanged && subStatus != Constants.SSTATUS_OFFERED){

                        if (subStatus == Constants.SSTATUS_PENDING && newSub.Product__c != null && productMap.get(newSub.Product__c).Print_Product__c &&
                            ( newSub.Voucher_Adjustment_Reason__c == null && 
                                (newSub.Payment_Type__c == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL || 
                                    (newSub.isContinuous__c && newSub.Payment_Type__c == Constants.CREDIT_CARD_PAYMENT_METHOD ) ) ) ){

                            //   ALLOW PRODUCT CHANGE
                            subsAllowedForProductChange.add(newSub.Id); 
                            if (newSub.SubscriberHasEmail__c){
                                accountsWithEmail.add(newSub.Subscriber__c);
                            }
                        } else if (isProductChangeAllowed && (allowedStatus.contains(subStatus) || 
                                    (subStatus == Constants.SSTATUS_PENDING && 
                                        ( (!newSub.isContinuous__c && newSub.Payment_Type__c == Constants.CREDIT_CARD_PAYMENT_METHOD) || 
                                            newSub.Voucher_Adjustment_Reason__c == null) ) ) ){

                            //   ALLOW PRODUCT CHANGE
                            subsAllowedForProductChange.add(newSub.Id);
                            if (newSub.SubscriberHasEmail__c){
                                accountsWithEmail.add(newSub.Subscriber__c);
                            }
                        } else { 
                            newSub.addError(String.format(Label.Cannot_Change_Product_On_Subscription, new List<String> {productMap.get(oldSub.Product__c).Name, productMap.get(newSub.Product__c).Name} ));
                            return;
                        }
                    }
                }

                if (subProductChanged && newSub.Product__c != null && productMap.get(newSub.Product__c).Print_Product__c && 
                        oldSub.Subscription_Status__c == newSub.Subscription_Status__c && 
                        oldSub.Subscription_Status__c == Constants.SSTATUS_OFFERED){

                    if (productLeadDaysMap != null && productLeadDaysMap.get(newSub.Product__c) != null){
                        firstClassLeadTime = productLeadDaysMap.get(newSub.Product__c);
                    }
                        
                    Date saturdayAdjustedRenewalDate = DateUtility.getDateOfNextNamedDay(Date.today(), 'Saturday');
                    Date newStartDate                = saturdayAdjustedRenewalDate.addDays(firstClassLeadTime);

                    if(DateUtility.DayOfWeek(newStartDate) != 'Monday'){
                        newStartDate = DateUtility.getDateOfNextNamedDay(newStartDate, 'Monday');
                    }                    

                    if(newStartDate > newSub.Start_Date__c){
                        newSub.Start_Date__c = newStartDate;
                    } 
                }
            }

            if (!accountsWithEmail.isEmpty() && this.bRunAPI){
                UpdateSamUserDetailsBatch.callSamForUpdateAsync(accountsWithEmail, true, false);    
            }
        }
    }
}
