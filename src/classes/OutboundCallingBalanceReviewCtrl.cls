/**
* @author Pawel Chrzanowski
* @date 14/07/2016
* @description Controller for Outbound Calling Balance Review VF Page
#############Change Log#############
Modified by         Version     Change Date
Pawel Chrzanowski   1.1         28/07/2016  //added edit and closure functionality
Michal Szewczyk     1.2         27/09/2016  // changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
Mantas Grigaliunas  1.3         18/11/2016  //replaced Voucher Activity Refund Due field with Refund Status
**/
public class OutboundCallingBalanceReviewCtrl {

    public Case selectedCase {get;set;}
    public String casesTotal {get;set;}
    public Integer casesTotalCount {get;set;}
    public Decimal outstandingBalance {get;set;}
    public Boolean hasCustomer {get;set;}
    public Boolean hasPayments {get;set;}
    public Boolean hasVoucherActivities {get;set;}
    public Boolean isSaveButtonEnabled {get;set;}
    public Subscription__c customerSubscription {get;set;}
    public List<MPPInterfaceHTTP.OrderHistoryItem> customerMPPOrderHistory {get;set;}

    public String stageName {get;set;}
    public String outcome {get;set;}
    public String callDateTime {get;set;}
    public String priorityField {get;set;}
    public Integer offset {get;set;}
    public Id recordTypeId {get;set;}
    public Integer callRecordEntry {get;set;}

    @testVisible private List<Case> lstCases;
    @testVisible private static Integer initialCaseLimit = 200;
    @testVisible private static Integer caseLimit = 100;

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 14/07/2016
    Version - 1.0 
    Function - Constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public OutboundCallingBalanceReviewCtrl(){
        hasCustomer = false;
        hasPayments = false;
        hasVoucherActivities = false;
        isSaveButtonEnabled = false;
        casesTotalCount = 0;
        casesTotal = '0';

        //get related Outbound Call Setting
        List<Outbound_Call_Setting__c> lstOcs = [SELECT Case_Record_Type__c, Menu_Name__c, Order__c FROM Outbound_Call_Setting__c WHERE Active__c = true AND Visualforce_Page__c = :Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME];
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
    Developer - Pawel Chrzanowski
    Date - 14/07/2016
    Version - 1.0 
    Function - method to run dynamic SOQL on Case
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         27.09.2016  - changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
    ****************************************************************************************/
    private void getAvailableCases(Boolean isCount, Integer limitAmount){
        DateTime dateTimeNow = Datetime.now();
        String orderSegment = 'ORDER BY ' + (String.isNotBlank(priorityField) ? priorityField + ' DESC, ' : '') + callDateTime + ' DESC, OC_Subscription_Outstanding_Balance__c DESC NULLS LAST ';
        String query = 'SELECT ' + (isCount ? 'COUNT()' : 'Id') + ' FROM Case ' + 
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
    Developer - Pawel Chrzanowski
    Date - 14/07/2016
    Version - 1.0 
    Function - method to get customer
    #############Change Log#############
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1         18/11/2016  //replaced Voucher Activity Refund Due field with Refund Status
    ****************************************************************************************/
    public void getCustomer(){
        hasCustomer = false;
        hasPayments = false;
        hasVoucherActivities = false;
        isSaveButtonEnabled = false;
        selectedCase = null;
        customerSubscription = null;
        customerMPPOrderHistory = null;

        lstCases = null;
        getAvailableCases(false, caseLimit);

        //pick and lock one Case from the selected list
        for(Case c : lstCases){
            try{
                selectedCase = [SELECT  CaseNumber, Status, OC_Call_Stage__c, OC_Outcome__c, 
                                        AccountId, Account.Name, Account.Subscriber_Number_Static__c, Account.PersonEmail, 
                                        Account.PersonMobilePhone, Account.PersonHomePhone, Account.PersonMailingPostalCode, 
                                        Account.PersonMailingCountry, Account.PersonMailingState, Account.PersonMailingStreet, Account.PersonMailingCity, 
                                        Print_Subscription__c, Print_Subscription__r.Name, Print_Subscription__r.Product__c, Print_Subscription__r.Weekly_Price__c, 
                                        Print_Subscription__r.TCode__c, Print_Subscription__r.Start_Date__c, Print_Subscription__r.End_Date__c, 
                                        Print_Subscription__r.Outstanding_Balance_to_from_Customer__c, 
                                        Print_Subscription__r.Revenue_Write_off_Amount__c, Print_Subscription__r.Revenue_Write_off_Reason__c 
                                FROM Case 
                                WHERE Id = :c.Id FOR UPDATE];
                outstandingBalance = selectedCase.Print_Subscription__r.Outstanding_Balance_to_from_Customer__c;
            }catch(Exception e){
                continue;
            }
            break;
        }
        if(selectedCase == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.OC_Case_Not_Found));
            return;
        }
        hasCustomer = true;

        //Voucher Activities
        if(selectedCase.Print_Subscription__c != null){
            List<Subscription__c> lstSubs = [SELECT (SELECT Name, Voucher_Activity_Action__c, Adjustment_Type__c, Start_Date__c, End_Date__c, Fulfilled_Date__c, Refund_Status__c, Voucher_Value__c FROM Voucher_Activities__r) FROM Subscription__c WHERE Id = :selectedCase.Print_Subscription__c];
            if(!lstSubs.isEmpty() && lstSubs[0].Voucher_Activities__r.size() > 0){
                customerSubscription = lstSubs[0];
                hasVoucherActivities = true;
            }
        }

        //MPP Transaction Histories
        MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
        MPPInterfaceHTTP.UserOrderHistoryResult orders;
        try{
            orders = mpp.getUserOrderHistoryFromMPP(null, 
                                                    selectedCase.Account.Subscriber_Number_Static__c, 
                                                    Datetime.newInstanceGmt(selectedCase.Print_Subscription__r.Start_Date__c, Time.newInstance(0, 0, 0, 0)).addMonths(-1), 
                                                    Datetime.newInstanceGmt(selectedCase.Print_Subscription__r.End_Date__c, Time.newInstance(0, 0, 0, 0)).addMonths(1), 
                                                    null, 
                                                    true);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MPP_Order_History_Error + ' ' + e.getMessage()));
        }
        if(orders != null && !orders.OrderHistoryItems.isEmpty() && String.isNotBlank(orders.TotalNumberOfOrders)){
            customerMPPOrderHistory = orders.OrderHistoryItems;
            for(MPPInterfaceHTTP.OrderHistoryItem ohi : customerMPPOrderHistory){
                ohi.OrderDate = ohi.OrderDate.substring(8,10) + '/' + ohi.OrderDate.substring(5,7) + '/' + ohi.OrderDate.substring(0,4);
            }
            hasPayments = true;
        }

        selectedCase.put(callDateTime, Datetime.now().addMinutes(callRecordEntry));
        update selectedCase;
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 28/07/2016
    Version - 1.0 
    Function - method to enable save button
    #############Change Log#############`
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void enableSaveButton(){
        isSaveButtonEnabled = true;
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 28/07/2016
    Version - 1.0 
    Function - method to save selected customer
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         27.09.2016  - changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
    ****************************************************************************************/
    public void saveSelectedCustomer(){
        try{
            update selectedCase.Print_Subscription__r;
            update selectedCase;
            isSaveButtonEnabled = false;
        }catch(DMLException e){
            ApexPages.addMessages(e);
        }

        List<Case> lstCases = [SELECT Status, Print_Subscription__r.Outstanding_Balance_to_from_Customer__c, Print_Subscription__r.Subscription_Status__c, Print_Subscription__r.End_Date__c FROM Case WHERE Id = :selectedCase.Id];
        if(!lstCases.isEmpty()){
            selectedCase.Status = lstCases[0].Status;
            outstandingBalance = lstCases[0].Print_Subscription__r.Outstanding_Balance_to_from_Customer__c;

            if(outstandingBalance == 0 && selectedCase.Status == Constants.CASE_STATUS_COMPLETED && lstCases[0].Print_Subscription__r.Subscription_Status__c == Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS && lstCases[0].Print_Subscription__r.End_Date__c < DateTime.now()){
                lstCases[0].Print_Subscription__r.Subscription_Status__c = Constants.SUBSCRIPTION_CANCELLED_STATUS;
                try{
                    update lstCases[0].Print_Subscription__r;
                }catch(DMLException e){
                    ApexPages.addMessages(e);
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 28/07/2016
    Version - 1.0 
    Function - method to redirect user to one off payment
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public PageReference takeOneOffPayment(){
        PageReference pr = Page.SubscriptionOneOffPaymentAmount;
        pr.getParameters().put('id', selectedCase.Print_Subscription__c);
        pr.getParameters().put('flow', Constants.OC_BALANCE_REVIEW_FLOW_NAME);
        return pr;
    }
}