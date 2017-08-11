/**
* @author Unknown
* @date Unknown
* @description Date utilities
#############Change Log#############
Modified by     Version     Change Date
Pawel Chrzanowski 1.1   23/02/2016  //added fix for getPaymentCollectionDate
**/

public with sharing class TMGDateExtension 
{
    /*
        Get these from custom setting 
    */
    public static Integer AUDDIS_DELAY {
    	get{
    		try{
    			return DD_Submission__c.getInstance('MPP DD Submission').AUDDIS_DELAY__c.intValue();
    		}catch(System.Exception e){
    			return 5;
    		}
    	}
    	private set;
    }
    public static String DAILY_CUTOFF_TIME { 
    	get{
    		try{
    			return DD_Submission__c.getInstance('MPP DD Submission').DAILY_CUTOFF_TIME__c;
    		}catch(System.Exception e){
    			return '21:00';
    		}
    	}
    	private set;
    }
    

    public static Date GetDDFileSubmissionDate(DateTime paymentDate, Map<Date, Holiday__c> holidayMap)
    {
    	DateTime dateToCheck = (IsTimeBefore(paymentDate, DAILY_CUTOFF_TIME) ? paymentDate : ToDateTime(GetNextBusinessDay(paymentDate.addDays(1), holidayMap)));
        return GetNextAUDDISDate(dateToCheck, holidayMap);
    }
    
    public static Date GetNextBusinessDay(DateTime dateToCheck, Map<Date, Holiday__c> holidayMap)
    {
    	if(!holidayMap.containsKey(ToDate(dateToCheck)) && !IsWeekEnd(ToDate(dateToCheck))){
        	return ToDate(dateToCheck);
    	}
    	return GetNextBusinessDay(dateToCheck.addDays(1), GetHolidayMap());
    }
      
    public static Date GetNextAUDDISDate(DateTime dateToCheck, Map<Date, Holiday__c> holidayMap)
    {
    	Integer currentDays = 0;
    	Date currentDate = ToDate(dateToCheck);
    	
    	while(currentDays < AUDDIS_DELAY){
    		currentDate = currentDate.addDays(1);
    		if(!holidayMap.containsKey(currentDate) && !IsWeekEnd(currentDate)){
    			currentDays++;
    		}	
    	}
    	return currentDate;
    }
    
    public static Date GetNextWorkingDate(Date dateToCheck, Integer daysToAdd, Map<Date, Holiday__c> holidayMap)
    {
    	Integer currentDays = 0;
    	Date currentDate = dateToCheck;
    	
    	while(currentDays < daysToAdd){
    		currentDate = currentDate.addDays(1);
    		if(!holidayMap.containsKey(currentDate) && !IsWeekEnd(currentDate)){
    			currentDays++;
    		}	
    	}
    	return currentDate;
    }
    
    public static String GetDayOfMonthSuffix(Integer n) 
    {
	    String[] suffix = new List<String>{'th', 'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th'};
		Integer m = Math.mod(n, 100);
		return String.valueOf(suffix[(m > 10 && m < 20) ? 0 : (Math.mod(m, 10))]);
	}
    
    public static Date ToDate(DateTime dateToConvert)
    {
        return dateToConvert.dateGMT();
    }
    
    public static DateTime ToDateTime(Date dateToConvert)
    {
        return DateTime.newInstanceGmt(dateToConvert.year(), dateToConvert.month(), dateToConvert.day());
    }
    
    public static Boolean IsWeekEnd(Date dateToCheck)
    {
        Integer dayOfWeek = dateToCheck.toStartOfWeek().daysBetween(dateToCheck);
        return (dayOfWeek == 5 || dayOfWeek == 6);
    }
    
    public static Map<Date, Holiday__c> GetHolidayMap()
    {
    	Map<Date, Holiday__c> holidayMap = new Map<Date, Holiday__c>();
    	for(Holiday__c holiday :Holiday__c.getAll().values()){
    		holidayMap.put(holiday.Holiday_Date__c, holiday);
    	}
    	return holidayMap;
    }
    
    private static Time GetTimeFromString(String timeToCheck)
    {
        Integer hour = Integer.valueOf(timeToCheck.split(':')[0]);
        Integer minute = Integer.valueOf(timeToCheck.split(':')[1]);
        return Time.newInstance(hour, minute, 0, 0);
    }
    
    private static Boolean IsTimeBefore(DateTime dateToCheck, String timeToCheck/*24 hour clock*/)
    {
        System.debug('### CHECK TIME: ' + dateToCheck.dateGMT() + ' : ' + (dateToCheck.timeGmt() <= GetTimeFromString(timeToCheck)));
        return (dateToCheck.timeGmt() <= GetTimeFromString(timeToCheck));
    }


    /**
     * Added as part of PP-1696
     * This method returns the previous working date from the dateToCheck param and previous days as passed
     * as param daysToSubstract. It checks if the previous working date is a holiday or weekend then traverses
     * the next previous working day accordingly.
     *
     * @param dateToCheck		the baseline date to which previous working date is to be calculated 
     * @param daysToSubstract	number of days to traverse back from the dateToCheck 
     * @param holidayMap		map containing holiday details to validate that the previous working date is not a holiday or weekend
     * @return	the daysToSubstract-th previous working date from the date passed as argument
     */
    public static Date getPreviousWorkingDate(Date dateToCheck, Integer daysToSubstract, Map<Date, Holiday__c> holidayMap) {
    	Integer difference = 0;
    	Date currentDate = dateToCheck;
    	
    	while(difference < daysToSubstract) {
    		currentDate = currentDate.addDays(-1);
    		if(!holidayMap.containsKey(currentDate) && !IsWeekEnd(currentDate)) {
    			difference++;
    		}
    	}
    	return currentDate;
    }
    

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0 
    A utility method to calculate the payment collection date from the payment submission date
    
    @param paymentSubmissionDate the date when MPP attempts the payment transaction with Bank. 
                                 In case of DirectDebit this is the date when MPP generates the BACS file to send to our Bank. 
                                 For Card payments there is no delay
    
    @return                      the date (payment collection date) when Bank completes the transaction and money is debited 
                                 from customer account. 
                                 This is normally two working days from the payment submission date in case of DirectDebit. 
                                 For Card, this is same as payment submission date

    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         23.02.2016      Added hotfix for incorrect MMP Pay Schedule End Date    
    ****************************************************************************************/     
	public static Date getPaymentCollectionDate(Date paymentSubmissionDate) {
		System.debug('Payment Submission Date : ' + paymentSubmissionDate);
		Integer dayOfMonth = paymentSubmissionDate.day();
		Date paymentCollectionDate;
		
		Boolean fixMPP = false;
		if(General__c.getInstance(Constants.GENERAL_FIX_MPP_PAY_SCHEDULE_END_DATE) != null && General__c.getInstance(Constants.GENERAL_FIX_MPP_PAY_SCHEDULE_END_DATE).Value_Boolean__c != null){
			fixMPP = General__c.getInstance(Constants.GENERAL_FIX_MPP_PAY_SCHEDULE_END_DATE).Value_Boolean__c;
		}
		
		if(dayOfMonth != 1 && dayOfMonth != 15) {
			system.debug('Day of Month not equal to 1 AND 15..');
			if(dayOfMonth > 15) {
                if(dayOfMonth<20 && fixMPP){
                    paymentCollectionDate = Date.newInstance(paymentSubmissionDate.year(), paymentSubmissionDate.month(), 15);
                }else{
    				Date tempDate = paymentSubmissionDate.addMonths(1);
    				paymentCollectionDate = Date.newInstance(tempDate.year(), tempDate.month(), 1);
    				System.debug('Calculating payment collection date by adding 1 month and setting day to 1 ..');
                }
			}else{
                if(dayOfMonth<5 && fixMPP){
                    paymentCollectionDate = Date.newInstance(paymentSubmissionDate.year(), paymentSubmissionDate.month(), 1);
                }else{
				    paymentCollectionDate = Date.newInstance(paymentSubmissionDate.year(), paymentSubmissionDate.month(), 15);
				    System.debug('Calculating payment collection date as payment submission date and setting day to 15 ..');
                }
			}
		} else {
			paymentCollectionDate = paymentSubmissionDate;
			system.debug('No match found. Payment collection date equals payment submission date ..');
		}
		system.debug('Payment Collection Date : ' + paymentCollectionDate);
		return paymentCollectionDate;
	}
}