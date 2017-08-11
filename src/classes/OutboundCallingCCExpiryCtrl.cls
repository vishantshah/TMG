/**
* Author:       Michal Szewczyk
* Date:         27/07/2016
* Description:  CC Expiry Date page controller
*
* ******************* Change Log *******************
* Modified by       Change Date
**/
public with sharing class OutboundCallingCCExpiryCtrl {
    
    public Case selectedCase {get;set;}
    public String casesTotal {get;set;}
    public Integer casesTotalCount {get;set;}
    public Boolean hasCustomer {get;set;}
    public Boolean hasPayments {get;set;}
    public Boolean hasVoucherActivities {get;set;}
    public Boolean isLastCustomer {get;set;}
    public Boolean isSaveButtonEnabled {get;set;}
    public Subscription__c customerSubscription {get;set;}

    public String stageName {get;set;}
    public String outcome {get;set;}
    public String callDateTime {get;set;}
    public String priorityField {get;set;}
    public Integer offset {get;set;}
    public Id recordTypeId {get;set;}
    public Integer callRecordEntry {get;set;}
    public MPPInterfaceHTTP mpp {get;set;}

    @testVisible private List<Case> lstCases;
    @testVisible private static Integer initialCaseLimit = 200;
    @testVisible private static Integer caseLimit = 100;

    
    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 27/07/2016
    Version - 1.0 
    Function - Constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public OutboundCallingCCExpiryCtrl() {
        
        hasCustomer = false;
        hasPayments = false;
        hasVoucherActivities = false;
        isLastCustomer = false;
        casesTotalCount = 0;
        casesTotal = '0';

        mpp = new MPPInterfaceHTTP();

        //get related Outbound Call Setting
        List<Outbound_Call_Setting__c> lstOcs = [SELECT Case_Record_Type__c, Menu_Name__c, Order__c FROM Outbound_Call_Setting__c WHERE Active__c = true AND Visualforce_Page__c = :Constants.OC_CREDIT_CARD_EXPIRY_VF_PAGE_NAME];
        if(lstOcs.isEmpty() || String.isBlank(lstOcs[0].Case_Record_Type__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.OC_OCS_Incomplete));
            return;
        }
        recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, lstOcs[0].Case_Record_Type__c, Case.class.getName());

        //parse related Outbound Call Setting's Parameters
        List<OutboundCallingBean.CallStageMapping> lstCsm;
        try{
            lstCsm = OutboundCallingUtils.getCallStageParametersByOCsettingId(lstOcs[0].Id);
            stageName = lstCsm[0].stagename;
            outcome = lstCsm[0].outcome;
            callDateTime = lstCsm[0].calldatetime;
            offset = lstCsm[0].offset;            
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.OC_OCS_Parameters_Error + ' ' + e.getMessage()));
            return;
        }

        //get related Outbound Call Rule
        List<Outbound_Call_Rule__c> lstOcr = [SELECT Call_Answered__c, Call_Busy__c, Call_No_Answer__c, Call_Record_Entry__c, Priority_Field__c FROM Outbound_Call_Rule__c WHERE Active__c = true AND Outbound_Call_Setting__c = :lstOcs[0].Id];
        if(!lstOcr.isEmpty()){
            callRecordEntry = (Integer)lstOcr[0].Call_Record_Entry__c;
            if(String.isNotBlank(lstOcr[0].Priority_Field__c)){
                priorityField = lstOcr[0].Priority_Field__c;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.OC_OCR_Not_Found));
            return;
        }

        //initial query to count available Cases
        getAvailableCases(true, initialCaseLimit);
    }

    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 27/07/2016
    Version - 1.0 
    Function - method to run dynamic SOQL on Case
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk  1.1        27/09/2016  // changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
    ****************************************************************************************/
    private void getAvailableCases(Boolean isCount, Integer limitAmount){
        DateTime dateTimeNow = Datetime.now();
        String orderSegment = 'ORDER BY ' + (String.isNotBlank(priorityField) ? priorityField + ' DESC, ' : '') + callDateTime + ' DESC, OC_Subscription_Outstanding_Balance__c DESC NULLS LAST ';
        String query = 'SELECT ' + (isCount ? 'count()' : 'Id') + ' FROM Case ' + 
                        'WHERE RecordTypeId = \'' + recordTypeId + '\' ' + 
                        'AND Status != \'' + Constants.CASE_STATUS_COMPLETED + '\' ' + 
                        'AND OC_Call_Stage__c = \'' + stageName + '\' ' + 
                        'AND ' + callDateTime + ' <= :dateTimeNow ' + 
                        (isCount ? '' : orderSegment) + 
                        'LIMIT ' + limitAmount;
        System.debug('### query: ' + query);

        if(isCount){
            casesTotalCount = Database.countQuery(query);
        }else{
            lstCases = Database.query(query);
            casesTotalCount = lstCases.size();
        }
        casesTotal = casesTotalCount == initialCaseLimit ? String.valueOf(initialCaseLimit) + '+' : String.valueOf(casesTotalCount);
    }

    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/07/2016
    Version - 1.0 
    Function - method to get customer
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk  1.1        16/11/2016 - Added try catch for mpp request
    ****************************************************************************************/
    public void getCustomer(){
        hasCustomer = false;
        hasPayments = false;
        hasVoucherActivities = false;
        isLastCustomer = false;
        selectedCase = null;
        isSaveButtonEnabled = false;
        customerSubscription = null;

        lstCases = null;
        getAvailableCases(false, caseLimit);

        if(casesTotalCount == 1){
            isLastCustomer = true;
        }

        //pick and lock one Case from the selected list
        for(Case c : lstCases){
            try{
                selectedCase = [select  CaseNumber, Status, OC_Outcome__c,OC_Scheduled_Callback__c,
                                        AccountId, Account.Name, Account.Subscriber_Number_Static__c, Account.PersonEmail, 
                                        Account.PersonMobilePhone, Account.PersonHomePhone, Account.PersonMailingPostalCode, 
                                        Account.PersonMailingCountry, Account.PersonMailingState, Account.PersonMailingStreet, Account.PersonMailingCity, 
                                        Print_Subscription__c, Print_Subscription__r.Name, Print_Subscription__r.Product__c, Print_Subscription__r.Weekly_Price__c, 
                                        Print_Subscription__r.TCode__c, Print_Subscription__r.Start_Date__c, Print_Subscription__r.End_Date__c 
                                    from Case 
                                    where Id = :c.Id for update];
            }catch(Exception e){
                continue;
            }
            break;
        }
        if(selectedCase == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.OC_Case_Not_Found));
            return;
        } 
        try{
            mpp.initialise(selectedCase.Account.Subscriber_Number_Static__c);
        }catch(Exception e){

        }

        hasCustomer = true;

        selectedCase.put(callDateTime, Datetime.now().addMinutes(callRecordEntry));
        update selectedCase;
    }

    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 02/08/2016
    Version - 1.0 
    Function - method to enable save button
    #############Change Log#############`
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void enableSaveButton(){
        isSaveButtonEnabled = true;
    }

    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 02/08/2016
    Version - 1.0 
    Function - method to save selected customer
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void saveSelectedCustomer(){
        try{
            update selectedCase;
            isSaveButtonEnabled = false;
        }catch(DmlException e){
            ApexPages.addMessages(e);
        }
        List<Case> lstCases = [SELECT Status, Print_Subscription__r.Outstanding_Balance_to_from_Customer__c FROM Case WHERE Id = :selectedCase.Id];
        selectedCase.Status = lstCases[0].Status;
    }

}