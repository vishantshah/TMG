/**
* @author Unknown
* @date Unknown
* @description Test class for ChequeTriggerHanlder
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         16/10/2015  //moved here testNewCheque() from ChequeIntoClosedBatchTriggerTest class
                                        //quickly refactored all test methods to use TestDataUtility not old unrelated test data generation class
Wiktor Czykin   1.2         01/03/2017  //added testSchoolSubsUpdate()
**/
@isTest
private class ChequeTriggerHandlerTest {
    
    static testMethod void testSubsUpdate() {
        TestDataUtility td = new TestDataUtility(1);
        td.checkChequeDependencies();

        Test.startTest();
            td.createCheques();
            List<Subscription__c> sub = [select Payment_Details_Received__c, total_dd_payment__c from subscription__c where Id = :td.lstSubscriptions[0].Id];
            System.assert(!sub.isEmpty());
            System.assert(sub[0].Payment_Details_Received__c);
            System.assert(sub[0].total_dd_payment__c == td.lstCheques[0].Cheque_Amount__c);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin 
    Date - 01/03/2017
    Version - 1.0
    Function - test change of sub status to pending on cheque insert - for school sub and not for others
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testSchoolSubsUpdate() {
        TestDataUtility td = new TestDataUtility(2);
        td.checkChequeDependencies();

        for(Subscription__c sub : td.lstSubscriptions){
            td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.sObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
            td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_OFFERED;
            td.lstSubscriptions[1].Subscription_Status__c = Constants.SSTATUS_OFFERED;
        }
        update td.lstSubscriptions;

        Test.startTest();
            td.createCheques();
        Test.stopTest();
        
        Map<Id, Subscription__c> lstRefetch = new Map<Id, Subscription__c>([select Id, Subscription_Status__c, Payment_Details_Received__c from Subscription__c where Id in :td.lstSubscriptions]);
        System.assert(!lstRefetch.isEmpty());
        
        for(Subscription__c s : lstRefetch.values()){
            System.assert(s.Payment_Details_Received__c);
        }
        System.assertEquals(Constants.SSTATUS_PENDING, lstRefetch.get(td.lstSubscriptions[0].Id).Subscription_Status__c);
        System.assertEquals(Constants.SSTATUS_OFFERED, lstRefetch.get(td.lstSubscriptions[1].Id).Subscription_Status__c);

    }
    
    static testMethod void testUpdateCheque() {
        TestDataUtility td = new TestDataUtility();
        td.createCheques();

        Test.startTest();
            update td.lstCheques;
            delete td.lstCheques;
            undelete td.lstCheques;
        Test.stopTest();
    }

    static testMethod void testNewCheque() {
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();   

        Cheque_Batch__c closedBatch = TestDataUtility.newChequeBatch(0);
        closedBatch.batch_closed_date__c = Date.today();
        insert closedBatch; 
        
        Cheque__c cheque = new Cheque__c(subscription__c = td.lstSubscriptions[0].id,
                               cheque_amount__c = 250,
                               ref_number_on_cheque__c = '2',
                               cheque_batch__c = closedBatch.id,
                               name_on_cheque__c = 'Fred Bloggs',
                               sort_code__c = '000000',
                               account_number__c = '12345678');
        try {
          insert cheque;
        } catch (Exception ex) {
    }
  }

}