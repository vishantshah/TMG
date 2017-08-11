/**
* @author Unknown
* @date Unknown
* @description UtilityLookupSubscriptionVariables class test
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         16/10/2015  //removed useless code. no time to restore the valid code.
**/
@isTest
private class UtilityLookupSubscriptionVariablesTest {

    private static testmethod void TestGetMainIncentives(){
        SubManagementDefaults__c newSubManagementDefaults = new SubManagementDefaults__c(ID__c='Incentive',DefaultValue__c='this is an incentive');
        insert newSubManagementDefaults;
        Test.startTest();
            System.assert(String.isNotBlank(UtilityLookupSubscriptionVariables.getMainIncentives()));
        Test.stopTest();
            
    } 

    private static testmethod void TestGetEmailIncentives(){ 
        SubManagementDefaults__c newSubManagementDefaults = new SubManagementDefaults__c(ID__c='EmailIncentive',DefaultValue__c='this is another incentive');
        insert newSubManagementDefaults;
        Test.startTest();
            System.assert(String.isNotBlank(UtilityLookupSubscriptionVariables.getEmailIncentives()));
        Test.stopTest();
    }
}