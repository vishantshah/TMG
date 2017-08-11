/**
* @author Pawel Chrzanowski
* @date 14/09/2016
* @description Test class for CasesByCallStageReport
#############Change Log#############
Modified by        Version    Change Date
Pawel Chrzanowski  1.1        21/01/2016
Pawel Chrzanowski  1.2        01/02/2016  Rewrote most methods to implement sorting and JSRemoting
Pawel Chrzanowski  1.3        09/08/2016  Added Custom Case Search
Pawel Chrzanowski  1.4        16/08/2016  Added Mass Email
**/
@isTest
private class CasesByCallStageReportTest {

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        14/09/2016
    Function    test for parseCaseCounter
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @isTest(SeeAllData='true') static void constructorTest(){
        Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        Outbound_Call_Setting__c ocSetting = new Outbound_Call_Setting__c(Case_Record_Type__c=Constants.OC_SALES_RECORD_TYPE_NAME, Default_Queue_Name__c='queue', Visualforce_Page__c='vf', Active__c=true, Reports__c = '["Cases_by_Call_Stage"]');
        insert ocSetting;

        ApexPages.StandardController sc = new ApexPages.StandardController(ocSetting);
        CasesByCallStageReport controller = new CasesByCallStageReport(sc);
    }
}