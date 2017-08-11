/**
* @author Matt Hime (Tquila)
* @date Unknown
* @description Some handy date manipulations
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         12-15/06/2015  //modified getDateOfNextNamedDay(), added isBeforExtractionTime()
**/
public class DateUtility {

	private static final date baseDate = date.valueOf('1899-01-01'); //THIS WAS A SUNDAY
	
	private static final map<integer, string> Day = new map<integer, string>{
		0 => 'Sunday',
		1 => 'Monday',
		2 => 'Tuesday',
		3 => 'Wednesday',
		4 => 'Thursday',
		5 => 'Friday',
		6 => 'Saturday'
	};
	private static final map<string, integer> DayPosition = new map<string, integer>{
		'Sunday' => 0,
		'Monday' => 1,
		'Tuesday' => 2,
		'Wednesday' => 3,
		'Thursday' => 4,
		'Friday' => 5,
		'Saturday' => 6
	};
	
	
	public class UtilityDateException extends Exception {}
	
	
	public static string DayOfWeek(date value){
		if(value != null){
			integer days = baseDate.daysBetween(value);
			system.debug('***days: '  + days);
		
			//If the number of days is negative,  value is a date in the past - don't know much about history (don't know much about biology)
			if(days > 0){
				integer remainder = math.mod(days, 7);
				system.debug('***remainder: '  + remainder);
			
				return Day.get(remainder);
			}
			else{
				throw new UtilityDateException('Day of Week calculation cannot be made for dates earlier than ' + baseDate.format());
			}
		}
		else{
			return null;
		}
	}
	
	public static date GetLastDateOfTheMonth(date value){
		if(value != null){
			date tempDate = value.addMonths(1);
			system.debug('***tempDate1: '  + tempDate);
			
			return tempDate.addDays(-tempDate.day());
		}
		else{
			return null;
		}
	}
	
	public static string GetLastDayOfTheMonth(date value){
		return DayOfWeek(GetLastDateOfTheMonth(value));
	}
	
	public static date getLastDateOfTheMonthForNamedDay(string namedDay, date month){
		
		date LDoM = DateUtility.GetLastDateOfTheMonth(month);
		system.debug('***LDoM: ' + LDoM);
		string lastDayName = DateUtility.DayOfWeek(LDoM);
		system.debug('***lastDayName: ' + lastDayName);

		integer namedDayPos = DayPosition.get(namedDay);
		integer lastDayPos = DayPosition.get(lastDayName);
		system.debug('***namedDayPos: ' + namedDayPos);
		system.debug('***lastDayPos: ' + lastDayPos);
		
		date result;
		if(lastDayPos >= namedDayPos){
			result = LDoM.addDays((lastDayPos - namedDayPos) * -1);
		}
		else{
			result = LDoM.addDays((lastDayPos + 7 - namedDayPos) * -1);
		}
		
		return result;
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 15/06/2015
    Version - 1.0
    Function - Checks if current time is before one set in custom settings for Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME name
    			This is to make sure Start Date is not set to a too early date.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static Boolean isBeforeExtractionTime(){
		General__c timeSetting = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME);
		if(timeSetting != null && String.isNotBlank(timeSetting.Value__c)){
			try{
				List<String> lstTimeParts = timeSetting.Value__c.split(Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME_SPLIT); 
				if(lstTimeParts.size() != 2 || !lstTimeParts[0].isNumeric() || !lstTimeParts[1].isNumeric()) throw new TelegraphApplicationException(Label.X23_days_renewal_Parsing_error_of_extract_cut_off_time);
				Time tSaturdayCutOff = Time.newInstance(Integer.valueOf(lstTimeParts[0]), Integer.valueOf(lstTimeParts[1]), 0, 0);
				Time tNowLocal = Datetime.now().time();
				System.debug('TMGLOG:DateUtility:isBeforExtractionTime:LOCAL'+tNowLocal+':CUTOFF:'+tSaturdayCutOff);
				if(tNowLocal < tSaturdayCutOff){
					return true;
				}
			}catch(Exception e){
				System.debug('TMGLOG:DateUtility:isBeforExtractionTime:error in time parsing:'+e.getMessage());
			}
		}
		return false;
	}

	/*************************************************************************************** 
    Developer - Matt Hime (Tquila)
    Date - Unknown
    Version - 1.1
    Function - gets date of closest endDay(String)
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/06/2015	//added custom settings based time condition check
    ****************************************************************************************/
	public static Date getDateOfNextNamedDay(Date startDate, String endDay){
		String startDateDay = DayOfWeek(startDate);
		if (startDateDay!=null) {
			Boolean bIsBeforeNow = isBeforeExtractionTime();
			
			Integer startDateDayPos = DayPosition.get(startDateDay);
			System.debug('TMGLOG:DateUtility:getDateOfNextNamedDay:startDateDayPos:' + startDateDayPos);
			
			Integer endDayPos = DayPosition.get(endDay);
			System.debug('TMGLOG:DateUtility:getDateOfNextNamedDay:endDayPos:' + endDayPos);
			
			Integer dayAdjustmentFactor;
			if((bIsBeforeNow && endDayPos == startDateDayPos) || endDayPos > startDateDayPos){
				dayAdjustmentFactor = endDayPos - startDateDayPos;
			}else{
				dayAdjustmentFactor = endDayPos + 7 - startDateDayPos;
			}
			System.debug('TMGLOG:DateUtility:getDateOfNextNamedDay:dayAdjustmentFactor: ' + dayAdjustmentFactor);
			
			return startDate.addDays(dayAdjustmentFactor);
		}
		
		return null;
	}
	
	public static date getDateOfPreviousNamedDay(date startDate, string endDay){
		
		string startDateDay = DayOfWeek(startDate);
		system.debug('***startDateDay: ' + startDateDay);
		
		integer startDateDayPos = DayPosition.get(startDateDay);
		system.debug('***startDateDayPos: ' + startDateDayPos);
		
		integer endDayPos = DayPosition.get(endDay);
		system.debug('***endDayPos: ' + endDayPos);
		
		integer dayAdjustmentFactor;
		if(startDateDayPos <= endDayPos){
			dayAdjustmentFactor = startDateDayPos + 7 - endDayPos;
		}
		else{
			dayAdjustmentFactor = startDateDayPos - endDayPos;
		}
		system.debug('***dayAdjustmentFactor: ' + dayAdjustmentFactor);
		
		return startDate.addDays(-dayAdjustmentFactor);
	}
    
    public static integer calculateAgeInYears(date startDate, date endDate){

    	integer interval = endDate.year() - startDate.year();
    	
		if (endDate.dayOfYear() < startDate.dayOfYear()){
			interval--;
		}
		
		return interval;
    }
	
}