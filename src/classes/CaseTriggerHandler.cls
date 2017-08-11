/**
* Author:       Michal Kwika (Accenture)
* Date:         22/01/2016
* Description:  TriggerHandler on Case Object
*
* ******************* Change Log *******************
* Modified by           Change Date
* Mantas Grigaliunas    18/07/2016  //new trigger handler method updateOutboundCallingStageHistory and OnBeforeUpdate method added
* Mantas Grigaliunas    31/08/2016  //added new trigger method updateAccountContact()
* Michal Szewczyk       10/10/2016  //added Decease update to account in updateAccountContact()
* Mantas Grigaliunas    19/10/2016  //modified updateOutboundCallingStageHistory()
* Michal Szewczyk       08/11/2016  //added updateProductNameOC method()
* Wiktor Czykin         22/11/2016  //modified updateOutboundCallingStageHistory();
* Wiktor Czykin         05/12/2016  //modified updateProductNameOC()
* Pawel Chrzanowski     06/12/2016  //added verifyOnlyOneOCSCase()
* Wiktor Czykin         07/12/2016  //modified updateOutboundCallingStageHistory()
* Pawel Chrzanowski     14/12/2016  //added updateSubscription();
* Wiktor Czykin         21/12/2016  //added account population to product population method and renamed it to updateProductNameAndAccountIdOC()
* Pawel Chrzanowski     10/01/2017  //modified updateOutboundCallingStageHistory()
* Pawel Chrzanowski     26/01/2016  //modified verifyOnlyOneOCSCase() and renamed to verifyOnlyOneOCCase()
* Wiktor Czykin         01/02/2017  //modified updateAccountContact()
* Pawel Chrzanowski     28/03/2017  //modified updateProductNameAndAccountIdOC()
* Konrad Czykin         12/06/2017  //added new trigger method linkCharterOrphanCases()
* Vishant Shah          20/07/2017  //added validateCases
* Vishant Shah          13/06/2017  //Added caseClassification to update Case fields based on OCS.Case_Field_Map__c
**/
public class CaseTriggerHandler {
    // Boolean to control recursion
    public Boolean isExecuting = false;
    //triggerhandler instance
    private static CaseTriggerHandler instance;
    //static rt id for  failed payment
    public static Id failedPaymentRecTypeId = Constants.getFailedPaymentRT();

    public static CaseTriggerHandler getInstance() {
        if (instance == null) instance = new CaseTriggerHandler();
        return instance;
    }

    public void OnBeforeInsert(Case[] newCases) {
        if (!this.isExecuting) {
            this.isExecuting = true;

            setShortDescriptionOnGatewayResponse(newCases);
            updateProductNameAndAccountIdOC(newCases, null);
            updateAccountContact(newCases);
            verifyOnlyOneOCCase(newCases);
            updateOutboundCallingStageHistory(newCases, null);

            validateCases(newCases);

            this.isExecuting = false;
        }
    }

    public void OnAfterInsert(Case[] newCases) {
        if (!this.isExecuting) {
            this.isExecuting = true;

            linkCharterOrphanCases(newCases);
            
            this.isExecuting = false;
        }
    }

     public void OnBeforeUpdate(Case[] newCases, Map<Id, Case> oldCasesMap) {
        if (!this.isExecuting) {
            this.isExecuting = true;

            updateOutboundCallingStageHistory(newCases, oldCasesMap);
            updateProductNameAndAccountIdOC(newCases, oldCasesMap);
            updateAccountContact(newCases);
            verifyOnlyOneOCCase(newCases);
			updateSubscription(newCases);

            validateCases(newCases);

            this.isExecuting = false;
        }
    }

    public void OnAfterUpdate(Case[] newCases, Map<Id, Case> oldCasesMap) {
        if (!this.isExecuting) {
            this.isExecuting = true;

            linkCharterOrphanCases(newCases);
            
            this.isExecuting = false;
        }
    }
    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 22/01/2016
    Version - 1.0
    Function -  When a failed Payment Case is created - check if there is a gateway response
                code there. If available get description from Custom Settings based on code
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void setShortDescriptionOnGatewayResponse(Case[] newCases) {
        if (newCases != null) {
            for (Case tempCase : newCases) {
                if (tempCase.RecordTypeId == failedPaymentRecTypeId && String.isNotBlank(tempCase.Gateway_Reason_code__c) && tempCase.Gateway_Reason_code_source__c != null) {
                    String shortDescription = getGatewayShortDescriptionBasedOnSource(tempCase.Gateway_Reason_code_source__c, tempCase.Gateway_Reason_code__c);
                    if (shortDescription != null) {
                        tempCase.Gateway_Reason_Code_detail__c = tempCase.Gateway_Reason_code_source__c + '-' + tempCase.Gateway_Reason_code__c + ' ' + shortDescription;
                    } else {
                        tempCase.Gateway_Reason_Code_detail__c = tempCase.Gateway_Reason_code_source__c + '-' + tempCase.Gateway_Reason_code__c ;
                    }

                }
            }
        }
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 22/01/2016
    Version - 1.0
    Function -  Get Gateway short description from Custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private String getGatewayShortDescriptionBasedOnSource(String source, String numCode) {
        if(source.contains(Constants.CASE_REASONCODE_ADDACS)){
            source = Constants.CASE_REASONCODE_ADDACS;
        }
        String fullKey = source + '-' + numCode;
        String shortDescription;

        try {
            shortDescription = GeatewayReasonCodes__c.getInstance(fullKey).Short_Description__c;
        }catch (Exception ex) {
            System.debug('### Error: CaseTriggerHandler: There is no gateway code like this one on Case!');
            return null;
        }

        System.debug('### CaseTriggerHandler: shortDescription: ' + shortDescription);

        return shortDescription;
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 12/07/2016
    Version - 1.2
    Function -  Updated Outbound Calling case stage outcomes history
    #############Change Log#############
    Modified by         Change Date
    Mantas Grigaliunas  19/10/2016  Added the condition to update history if No Sale Reason changed
    Wiktor Czykin       22/11/2016  Excluded scheduled call date-time updating stage respective datetime when scheduled callback is null
    Wiktor Czykin       07/12/2016  Modified so that it partially executes on insert as well
	Pawel Chrzanowski   10/01/2017  Added conditions for Reschedule
    Vishant Shah        13/06/2017  Added caseClassification to update Case fields based on OCS.Case_Field_Map__c
    ****************************************************************************************/
    private void updateOutboundCallingStageHistory(Case[] newCases, Map<Id, Case> oldCasesMap){

        List<Case> ocSalesCasesList = new List<Case>();
        
        //get the set of the record type ids that are defined in the outbound call settings records
        Set<String> outboundCallCaseRecordTypeIdsSet          = new Set<String>(OutboundCallingUtils.getOutboundCallingCaseRecordTypesIds());
        Map<String, Map<String, String>> classificationFields = OutboundCallingUtils.getCaseClassificationMapByRecordTypeId();

        //get a list of the cases that record type is set in Outbound Call Settings records
        if(oldCasesMap != null){
            for(Case thisCase : newCases){
                //update only OC cases that OC_Outcome__c or No_Sale_Reson__c fields was changed set
                if(
                    outboundCallCaseRecordTypeIdsSet.contains(thisCase.RecordTypeId) 
                    && (
                        oldCasesMap.get(thisCase.Id).OC_Outcome__c != thisCase.OC_Outcome__c
                        || oldCasesMap.get(thisCase.Id).OC_No_Sale_Reason__c != thisCase.OC_No_Sale_Reason__c
                        || (oldCasesMap.get(thisCase.Id).OC_Scheduled_Callback__c != thisCase.OC_Scheduled_Callback__c && thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE)
                    )
                ){
                    ocSalesCasesList.add(thisCase);
                }
            }
        }else{
             for(Case thisCase : newCases){
                //update all OC cases on insert
                if(outboundCallCaseRecordTypeIdsSet.contains(thisCase.RecordTypeId)){
                    ocSalesCasesList.add(thisCase);
                }
            }
        }
            
        if(!ocSalesCasesList.isEmpty()){

            try{
                //get all the outbound call settings that contains parameters
                OutboundCallingUtils.defineOutboundCallSettingParameters();
                for(Case thisCase : ocSalesCasesList){
                    //get outbound call paramters JSON object list for the specific case record type
                    List<OutboundCallingBean.CallStageMapping> thisParamList = OutboundCallingUtils.getCallStageParametersByRecordTypeId(thisCase.RecordTypeId);
                    //loop through callStageParameters list and 
                    for(OutboundCallingBean.CallStageMapping thisParam : thisParamList){
                        //updated the the case fields OC_Stage_<n>_Outcome__c, OC__Stage_<n>_Call_Date_Time__c and OC__Stage_<n>_No_Sale_Reason__c based on the Call_Stage specified
                        if(thisParam.stagename.equals(thisCase.OC_Call_Stage__c)){
                            thisCase.put(thisParam.outcome, thisCase.OC_Outcome__c);
                            if (oldCasesMap != null){
                                thisCase.Outcome_Changed_On__c = Datetime.now();
                            }
                            //if no sale reason is defined update the no sale reason field
                            if(String.isNotBlank(thisParam.nosalereason))
                                thisCase.put(thisParam.nosalereason, thisCase.OC_No_Sale_Reason__c);
                            //update OC_Scheduled_Callback__c only if it was modified by controller or user
                            if((oldCasesMap == null || (oldCasesMap.get(thisCase.Id).OC_Scheduled_Callback__c != thisCase.OC_Scheduled_Callback__c)) && thisCase.OC_Scheduled_Callback__c != null){
                                thisCase.put(thisParam.calldatetime, thisCase.OC_Scheduled_Callback__c);
                            } else if(oldCasesMap != null || thisCase.OC_Outcome__c != Constants.OC_DEFAULT_OUTCOME){
                                thisCase.put(thisParam.calldatetime, DateTime.now());
                            }
                        }
                    }
                }

            } catch(TelegraphApplicationException e){ //catch the exceptions that are thrown in OutboundCallingUtils class
                for(Case thisCase : ocSalesCasesList)
                    thisCase.addError(e);
            }
        }

        for (Case thisCase : newCases){
            if (classificationFields.containsKey(thisCase.RecordTypeId)){
                Map<String, String> caseFieldMap = classificationFields.get(thisCase.RecordTypeId);

                if (caseFieldMap != null){
                    for (String field : caseFieldMap.keySet()){
                        if (thisCase.get(field) == 'Outbound Renewal Tracker')
                            thisCase.put(caseFieldMap.get(field), 'Renewal');
                        else 
                            thisCase.put(caseFieldMap.get(field), thisCase.get(field));
                    }
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 08/11/2016
    Version - 1.1
    Function -  Updated Product field baased on product on sub
    #############Change Log#############
    Modified by         Change Date
    Wiktor Czykin       05/11/2016  //modified so that it works
	Pawel Chrzanowski   28/03/2017  //allowed AccountId population despite no Product on Subscription
    ****************************************************************************************/
    private void updateProductNameAndAccountIdOC(Case[] newCases, Map<Id, Case> oldCasesMap){
        //get the set of the record type ids that are defined in the outbound call settings records
        Set<String> outboundCallCaseRecordTypeIdsSet = new Set<String>(OutboundCallingUtils.getOutboundCallingCaseRecordTypesIds());
        Set<Id> setZSubscriptionsId = new Set<Id>();
        Set<Id> setPrintSubscriptionsId = new Set<Id>();

        for(Case thisCase : newCases){
            //update only OC cases that OC_Outcome__c is Sale
            if(outboundCallCaseRecordTypeIdsSet.contains(thisCase.RecordTypeId)){// && thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_SALE){
                if(thisCase.Subscription__c != null){
                    setZSubscriptionsId.add(thisCase.Subscription__c);
                }else if(thisCase.Print_Subscription__c != null){
                    setPrintSubscriptionsId.add(thisCase.Print_Subscription__c);
                }
            }
        }
        Map<Id, SubscriptionToCaseItem> mapIdToItem = new Map<Id, SubscriptionToCaseItem>();
        if(!setPrintSubscriptionsId.isEmpty()){
            for(Subscription__c sub : [select Product__c, Product__r.Name, Subscriber__c from Subscription__c where Id in :setPrintSubscriptionsId]){
                mapIdToItem.put(sub.Id, new SubscriptionToCaseItem(sub.Subscriber__c, sub.Product__r.Name));
            }
        }
        if(!setZSubscriptionsId.isEmpty()){
            for(Zuora__Subscription__c zs : [select Subscription_Product__c, Zuora__Account__c from Zuora__Subscription__c where Id in :setZSubscriptionsId]){
                mapIdToItem.put(zs.Id, new SubscriptionToCaseItem(zs.Zuora__Account__c, zs.Subscription_Product__c));
            }
        }

        for(Case thisCase : newCases){
            SubscriptionToCaseItem stci;
            if(thisCase.Subscription__c != null){
                stci = mapIdToItem.get(thisCase.Subscription__c);
            }else if(thisCase.Print_Subscription__c != null) {
                stci = mapIdToItem.get(thisCase.Print_Subscription__c);
            }
            if(stci != null){
                if(thisCase.OC_Outcome__c  == Constants.CASE_OUTCOME_SALE){
                    thisCase.Product__c = stci.sProduct;
                }
                if(stci.accountId != null){
                    thisCase.AccountId = stci.accountId;
                }
            }
        }
    }

    /***************************************************************************************
    Date - 31/08/2016
    Version - 1.2
    Function -  Update Account Name or Contact Name fields based on what is assigned
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         10/10/2016  - added Decease update to account
    Wiktor Czykin   1.2         01/02/2017  - made sure we do not update account if it is not necessary
    ****************************************************************************************/
    private void updateAccountContact(Case[] newCases){

        List<Account> personAccountList;
        Map<Id, Id> personContactIdMap = new Map<Id, Id>();
        Map<Id, Id> personAccountIdMap = new Map<Id, Id>();
        Map<Id, Case> deceaseAccountIdToCase = new Map<Id,Case>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> accountToDecease = new Set<Id>();
        for(Case c : newCases){
            if(c.ContactId != null && c.AccountId == null) contactIdSet.add(c.ContactId);
            if(c.AccountId != null) accountIdSet.add(c.AccountId);
            if( (c.OC_Outcome__c == Constants.CASE_OUTCOME_DECEASED || c.NATC_Reason__c == Constants.CASE_OUTCOME_DECEASED) && c.Id != null) {
                accountToDecease.add(c.AccountId);
                deceaseAccountIdToCase.put(c.AccountId,c);
            }
        }
        //populated account if contact is related to person account and account is not populated
        if(contactIdSet.size() > 0){
            personAccountList = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId IN :contactIdSet]);
        
            if(personAccountList.size() > 0){
                for(Account a : personAccountList){
                    personContactIdMap.put(a.PersonContactId, a.Id);
                }
            }
            if(personContactIdMap.size() > 0){
                for(Case c : newCases){
                    if(personContactIdMap.containsKey(c.ContactId)){
                        c.AccountId = personContactIdMap.get(c.ContactId);
                    }
                }
            }
        }
        //populate contact if populated account is person account
        if(accountIdSet.size() > 0){
            personAccountList = new List<Account>([SELECT Id, PersonContactId,Deceased__pc FROM Account WHERE IsPersonAccount = true AND Id IN :accountIdSet]);
        
            if(personAccountList.size() > 0){
                List<Account> lstToUpdateDeceased = new List<Account>();
                for(Account a : personAccountList){
                    personAccountIdMap.put(a.Id, a.PersonContactId);
                    if(accountToDecease.contains(a.Id)) {
                        a.Deceased__pc = true;
                        lstToUpdateDeceased.add(a);
                    }
                }
                if(!lstToUpdateDeceased.isEmpty()){
                    Database.SaveResult[] saveResults =  Database.update(lstToUpdateDeceased,false);
                    for (Integer i = 0; i < saveResults.size(); i++) {
                        if (!saveResults[i].isSuccess()) {
                            if(deceaseAccountIdToCase.containsKey(lstToUpdateDeceased.get(i).Id)){
                                deceaseAccountIdToCase.get((lstToUpdateDeceased.get(i).Id)).addError(saveResults[i].getErrors()[0].getMessage());
                            }
                        }
                    }
                }
            }
            if(personAccountIdMap.size() > 0){
                for(Case c : newCases){
                    if(personAccountIdMap.containsKey(c.AccountId)){
                        c.ContactId = personAccountIdMap.get(c.AccountId);
                    }
                }
            }
        }
    }
	
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 06/12/2016
    Function to verify only one Outbound Calling Sales or Balance Review Case is assigned to a Print Subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void verifyOnlyOneOCCase(Case[] newCases){
        Map<Id, Case> subscriptionCaseOCSMap = new Map<Id, Case>();
        Map<Id, Case> subscriptionCaseOCBRMap = new Map<Id, Case>();
        Id ocsId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        Id ocbrId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME, Case.class.getName());

        for(Case c : newCases){
            if(c.RecordTypeId == ocsId && c.Print_Subscription__c != null){
                if(!subscriptionCaseOCSMap.containsKey(c.Print_Subscription__c)){
                    subscriptionCaseOCSMap.put(c.Print_Subscription__c, c);
                }else{
                    c.addError(Label.OC_Multiple_Sales_Cases_Trigger);
                    subscriptionCaseOCSMap.get(c.Print_Subscription__c).addError(Label.OC_Multiple_Sales_Cases_Trigger);
                }
            }
            if(c.RecordTypeId == ocbrId && c.Print_Subscription__c != null){
                if(!subscriptionCaseOCBRMap.containsKey(c.Print_Subscription__c)){
                    subscriptionCaseOCBRMap.put(c.Print_Subscription__c, c);
                }else{
                    c.addError(Label.OC_Multiple_Balance_Review_Cases_Trigger);
                    subscriptionCaseOCBRMap.get(c.Print_Subscription__c).addError(Label.OC_Multiple_Balance_Review_Cases_Trigger);
                }
            }
        }

        Map<Id, Subscription__c> subsForOCSCasesMap = new Map<Id, Subscription__c>([SELECT (SELECT Id FROM Cases__r WHERE RecordTypeId = :ocsId) FROM Subscription__c WHERE Id IN :subscriptionCaseOCSMap.keySet()]);
        Map<Id, Subscription__c> subsForOCBRCasesMap = new Map<Id, Subscription__c>([SELECT (SELECT Id FROM Cases__r WHERE RecordTypeId = :ocbrId) FROM Subscription__c WHERE Id IN :subscriptionCaseOCBRMap.keySet()]);

        for(Case c : newCases){
            if(c.RecordTypeId == ocsId && c.Print_Subscription__c != null){
                Integer caseAmount = subsForOCSCasesMap.get(c.Print_Subscription__c).Cases__r.size();
                if(caseAmount > 1 || (caseAmount == 1 && c.Id != subsForOCSCasesMap.get(c.Print_Subscription__c).Cases__r[0].Id)){
                    c.addError(Label.OC_Only_One_Sales_Case);
                }
            }
            if(c.RecordTypeId == ocbrId && c.Print_Subscription__c != null){
                Integer caseAmount = subsForOCBRCasesMap.get(c.Print_Subscription__c).Cases__r.size();
                if(caseAmount > 1 || (caseAmount == 1 && c.Id != subsForOCBRCasesMap.get(c.Print_Subscription__c).Cases__r[0].Id)){
                    c.addError(Label.OC_Only_One_Balance_Review_Case);
                }
            }
        }
    }
	
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 14/12/2016
    Function to update related Subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void updateSubscription(Case[] newCases){
        Map<Id, Case> subscriptionCaseMap = new Map<Id, Case>();
        List<Subscription__c> subsToUpdate = new List<Subscription__c>();

        Set<Id> recordTypeToExclude = new Set<Id>();
        recordTypeToExclude.add(RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Case.class.getName()));
        recordTypeToExclude.add(RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DDCX_CASE_RECORD_TYPE_NAME, Case.class.getName()));

        for(Case c : newCases){
            if(!recordTypeToExclude.contains(c.RecordTypeId)){
                if(c.OC_Outcome__c != null && c.OC_Outcome__c == Constants.CASE_OUTCOME_DECEASED && c.Print_Subscription__c != null){
                    subsToUpdate.add(new Subscription__c(Id = c.Print_Subscription__c, Subscription_Status__c = Constants.SSTATUS_DECLINED));
                    subscriptionCaseMap.put(c.Print_Subscription__c, c);
                }
            }
        }

        if(!subsToUpdate.isEmpty()){
            SubscriptionTriggerHandler.getInstance().bOcCaseUpdateSkip = true;
            Database.SaveResult[] saveResults =  Database.update(subsToUpdate, false);
            for(Integer i = 0; i < saveResults.size(); i++){
                if(!saveResults[i].isSuccess()){
                    subscriptionCaseMap.get(subsToUpdate[i].Id).addError(saveResults[i].getErrors()[0].getMessage());
                }
            } 
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/12/2016
    Simple wrapper to simplify mapping of multiple source subscriptions onto case
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private class SubscriptionToCaseItem{
        Id accountId;
        String sProduct;

        public SubscriptionToCaseItem(Id accountId, String sProduct){
            this.accountId = accountId;
            this.sProduct = sProduct;
        }
    }

    /***************************************************************************************
    Developer - Konrad Czykin
    Date - 05/06/2017
    Function to link orphan cases from charter no case in SF. After insert
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void linkCharterOrphanCases(Case[] newCases){
        Custom_Validation_Bypass__c cvb = Custom_Validation_Bypass__c.getInstance( UserInfo.getUserId() );
        
        if (!cvb.Bypass_Link_Orphan_Case__c){
            Set<String> setEmails = new Set<String>();
            Map<String, Id> memailcase = new Map<String, Id>();
            Map<String, Id> memailacc = new Map<String, Id>();
            List<Case> caseToUpdate = new List<Case>();
            Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.READER_RELATIONS_RECORD_TYPE_NAME, Case.class.getName());
            
            for(Case thisCase : newCases){
                if(thisCase.SuppliedEmail != null && thisCase.RecordTypeId == rtId)
                setEmails.add(thisCase.SuppliedEmail);
            }

            if(!setEmails.isEmpty()){
                //lsc - list of cases with the same Email as in newCases already in SF
                List<Case> lsc = [SELECT Id, ParentId, SuppliedEmail FROM Case WHERE RecordTypeId = :rtId AND SuppliedEmail = :setEmails AND ParentId = null AND Id != :newCases]; 
                //lacc - list of Accounts with email same as charter cases
                List<Account> lacc = [SELECT Id, PersonEmail, Number_of_Active_Subscriptions__c, LastModifiedDate FROM Account WHERE PersonEmail = :setEmails ORDER BY PersonEmail, Number_of_Active_Subscriptions__c DESC, LastModifiedDate DESC];
            
                if(!lacc.isEmpty()) memailacc.put(lacc[0].PersonEmail, lacc[0].Id);
                //take only first records from ordered list - records with different Email   
                if(lacc.size()>1){
                    for(Integer i=1; i<lacc.size(); i++){
                    if(lacc[i].PersonEmail != lacc[i-1].PersonEmail) memailacc.put(lacc[i].PersonEmail, lacc[i].Id);
                    }
                }

                if(!lsc.isEmpty()){
                    for(Case sfCase : lsc){
                        memailcase.put(sfCase.SuppliedEmail, sfCase.Id);
                    }
                }

                for(Case thisCase : newCases){
                
                    if (thisCase.RecordTypeId == rtId ){
                        Boolean accountFound = false;
                        Boolean caseFound    = false;

                        Case caseUpdate = new Case(Id = thisCase.Id);

                        if(memailacc.containsKey(thisCase.SuppliedEmail)){
                            caseUpdate.AccountId = memailacc.get(thisCase.SuppliedEmail);
                            accountFound = true;
                        }

                        if(!memailcase.containsKey(thisCase.SuppliedEmail)){ 
                            memailcase.put(thisCase.SuppliedEmail, thisCase.Id);
                        }

                        if (memailcase.containsKey(thisCase.SuppliedEmail) && memailcase.get(thisCase.SuppliedEmail) != thisCase.Id){
                            caseUpdate.ParentId = memailcase.get(thisCase.SuppliedEmail);
                            caseFound = true;
                        }

                        if (accountFound || caseFound){
                            caseToUpdate.add(caseUpdate);
                        }
                    }
                }
            
                Database.SaveResult[] saveResults =  Database.update(caseToUpdate, false);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (!saveResults[i].isSuccess())
                        caseToUpdate.get(i).Id.addError(saveResults[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 20/07/2017
    Function to  validate picklist values, bypass if user/profile defined in CustomValidationBypass 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void validateCases(List<Case> newCases){
        Custom_Validation_Bypass__c cvb = Custom_Validation_Bypass__c.getInstance(UserInfo.getUserId() );
        System.debug('cvb : ' + cvb);
        if (!cvb.Bypass_Custom_Validation_Rule__c){
            String objectName = newCases.getSObjectType().getDescribe().getName();
            CustomValidator.validate(objectName, newCases);
        }
    }
}