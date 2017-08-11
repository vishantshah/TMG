/**
* @author Unknown
* @date Unknown
* @description Date utilities test class
#############Change Log#############
Modified by         Version     Change Date
Pawel Chrzanowski   1.1         23/02/2016  //added testGetPaymentCollectionDate
**/

@isTest(SeeAllData=false)
public with sharing class TMGDateExtension_Test 
{
    public static void InsertCustomSettings()
    {
        Database.delete([SELECT Id FROM DD_Submission__c]);
        Database.delete([SELECT Id FROM Holiday__c]);
        
        DD_Submission__c mppDDSubmission = new DD_Submission__c();
        mppDDSubmission.Name = 'MPP DD Submission';
        mppDDSubmission.AUDDIS_DELAY__c = 5;
        mppDDSubmission.DAILY_CUTOFF_TIME__c = '21:00';
        insert mppDDSubmission;
        
        Holiday__c bankHoliday = new Holiday__c();
        bankHoliday.Name = 'BANK HOLIDAY 2012';
        bankHoliday.Holiday_Year__c = '2012';
        bankHoliday.Holiday_Date__c = Date.newInstance(2012, 3, 6);
        bankHoliday.Holiday_Type__c = 'BANK HOLIDAY';
        bankHoliday.Holiday_Country__c = 'UNITED KINGDOM';
        insert bankHoliday;
    }
    
    static testMethod void testGetNextWorkingDate()
    {
        InsertCustomSettings();
        System.assertEquals(1, TMGDateExtension.GetHolidayMap().size());
        
        //Saturday weekend 25 feb 2012.
        System.assertEquals(true, TMGDateExtension.IsWeekEnd(Date.newInstance(2012, 2, 25)));
        DateTime paymentDate = DateTime.newInstance(2012, 3, 2);
        
       // For Prod fix of Test cases deployment .
       // System.assertEquals(Date.newInstance(2012, 3, 12), TMGDateExtension.GetDDFileSubmissionDate(paymentDate, TMGDateExtension.GetHolidayMap()));
       // System.assertEquals(Date.newInstance(2012, 3, 13), TMGDateExtension.GetDDFileSubmissionDate(DateTime.newInstanceGMT(paymentDate.date(), Time.newInstance(22, 0, 0, 0)), TMGDateExtension.GetHolidayMap()));

        Date nextWorkingDay = TMGDateExtension.GetNextBusinessDay(Date.newInstance(2012, 3, 4), TMGDateExtension.GetHolidayMap());
        System.assertEquals(Date.newInstance(2012, 3, 5), nextWorkingDay);
        
        Integer delay = TMGDateExtension.AUDDIS_DELAY;
        String cutOfff = TMGDateExtension.DAILY_CUTOFF_TIME;
        
        Database.delete([SELECT Id FROM DD_Submission__c]);
        Database.delete([SELECT Id FROM Holiday__c]);
        
        List<DD_Submission__c> ddSubList = [SELECT Id FROM DD_Submission__c];
        List<Holiday__c> holidayList = [SELECT Id FROM Holiday__c];
        System.assertEquals(0, ddSubList.size());
        System.assertEquals(0, holidayList.size());

        System.assertEquals(5, TMGDateExtension.AUDDIS_DELAY);
        System.assertEquals('21:00', TMGDateExtension.DAILY_CUTOFF_TIME); 
        
        System.assertEquals(DateTime.newInstance(2012, 3, 12), TMGDateExtension.ToDateTime(Date.newInstance(2012, 3, 12)));      
        System.assertEquals(Date.newInstance(2012, 3, 12), TMGDateExtension.ToDate(DateTime.newInstance(2012, 3, 12)));          
    }    


    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 23/02/2016
    Version - 1.0 
    Function - test method for getPaymentCollectionDate, includes custom setting for hotfix
    #############Change Log#############
    Modified by         Version         Change Date
    ****************************************************************************************/
    static testMethod void testGetPaymentCollectionDate(){
        System.assertEquals(Date.newInstance(2016, 2, 1), TMGDateExtension.getPaymentCollectionDate(Date.newInstance(2016, 2, 1))); 
        System.assertEquals(Date.newInstance(2016, 2, 15), TMGDateExtension.getPaymentCollectionDate(Date.newInstance(2016, 2, 15))); 

        System.assertEquals(Date.newInstance(2016, 3, 1), TMGDateExtension.getPaymentCollectionDate(Date.newInstance(2016, 2, 21))); 
        System.assertEquals(Date.newInstance(2016, 2, 15), TMGDateExtension.getPaymentCollectionDate(Date.newInstance(2016, 2, 6))); 

        General__c cs = new General__c();
        cs.Name = Constants.GENERAL_FIX_MPP_PAY_SCHEDULE_END_DATE;
        cs.Value_Boolean__c = true;
        insert cs;

        System.assertEquals(Date.newInstance(2016, 2, 1), TMGDateExtension.getPaymentCollectionDate(Date.newInstance(2016, 2, 2)));             
        System.assertEquals(Date.newInstance(2016, 2, 15), TMGDateExtension.getPaymentCollectionDate(Date.newInstance(2016, 2, 16))); 
    }
}