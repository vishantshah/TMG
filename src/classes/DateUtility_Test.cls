/**
* @author Unknown
* @date Unknown
* @description Test class for DateUtility
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         12/06/2015 //added coverage for changes done to getDateOfNextNamedDay()
**/
@isTest
private class DateUtility_Test {
  
	static testMethod void testYearIntervalCalculation(){
		system.assertEquals(0, DateUtility.calculateAgeInYears(date.newInstance(1974, 2, 7), date.newInstance(1974, 12, 31)));
		system.assertEquals(9, DateUtility.calculateAgeInYears(date.newInstance(1974, 2, 7), date.newInstance(1984, 2, 6)));
		system.assertEquals(10, DateUtility.calculateAgeInYears(date.newInstance(1974, 2, 7), date.newInstance(1984, 2, 7)));
	}
	
	static testMethod void testDayOfWeekCalculation(){
		map<integer, string> testDates = new map<integer, string>{
			0 => 'Wednesday',
			1 => 'Thursday',
			2 => 'Friday',
			3 => 'Saturday',
			4 => 'Sunday',
			5 => 'Monday',
			6 => 'Tuesday'
		};
		
		date d = date.valueOf('2012-10-31'); //Wednesday
		for(integer i : testDates.keySet()){
			system.assertEquals(testDates.get(i), DateUtility.DayOfWeek(d.addDays(i)));
		}
		
		//Null value
		system.assertEquals(null, DateUtility.DayOfWeek(null));
		
		try{
			d = date.valueOf('1898-10-31'); //This will fail as it's too early
			DateUtility.DayOfWeek(d);
		}
		catch(Exception e){
			system.assertEquals('Day of Week calculation cannot be made for dates earlier than 01/01/1899', e.getMessage());
		}
	}
	
	static testMethod void testLastDayOfMonthCalculation(){
		//Past
		date d = date.valueOf('2001-11-09');
		system.assertEquals(date.valueOf('2001-11-30'), DateUtility.GetLastDateOfTheMonth(d));
		
		//Future
		d = date.valueOf('2020-07-01');
		system.assertEquals(date.valueOf('2020-07-31'), DateUtility.GetLastDateOfTheMonth(d));
		
		//Last day of month
		d = date.valueOf('2020-07-31');
		system.assertEquals(date.valueOf('2020-07-31'), DateUtility.GetLastDateOfTheMonth(d));
		
		//Leap year....
		d = date.valueOf('2012-02-09');
		system.assertEquals(date.valueOf('2012-02-29'), DateUtility.GetLastDateOfTheMonth(d));
		
		//Null value
		system.assertEquals(null, DateUtility.GetLastDateOfTheMonth(null));
	}

	public static testMethod void testLastDateOfTheMonthForNamedDay(){
		system.assertEquals(date.valueOf('2012-10-27'), DateUtility.getLastDateOfTheMonthForNamedDay('Saturday', date.valueOf('2012-10-06')));
		
		system.assertEquals(date.valueOf('2013-08-25'), DateUtility.getLastDateOfTheMonthForNamedDay('Sunday', date.valueOf('2013-08-02')));
		
		system.assertEquals(date.valueOf('2012-10-30'), DateUtility.getLastDateOfTheMonthForNamedDay('Tuesday', date.valueOf('2012-10-27')));
		
		system.assertEquals(date.valueOf('2013-04-25'), DateUtility.getLastDateOfTheMonthForNamedDay('Thursday', date.valueOf('2013-04-17')));
		
		system.assertEquals(date.valueOf('2012-10-31'), DateUtility.getLastDateOfTheMonthForNamedDay('Wednesday', date.valueOf('2012-10-31')));
	}
	
	static testMethod void testLastDayofTheMonth(){
		//Leap year test
		system.assertEquals('Wednesday', DateUtility.GetLastDayOfTheMonth(date.valueOf('2012-2-06')));
		
		//future test
		system.assertEquals('Sunday', DateUtility.GetLastDayOfTheMonth(date.valueOf('2025-11-25')));
	}
	
	static testMethod void testDateOfNextNamedDay(){
		date startDate = date.valueOf('2012-02-28'); //Testing over a leap year
		system.assertEquals(startDate.addDays(1), DateUtility.getDateOfNextNamedDay(startDate, 'Wednesday'));
		system.assertEquals(startDate.addDays(2), DateUtility.getDateOfNextNamedDay(startDate, 'Thursday'));
		system.assertEquals(startDate.addDays(3), DateUtility.getDateOfNextNamedDay(startDate, 'Friday'));
		system.assertEquals(startDate.addDays(4), DateUtility.getDateOfNextNamedDay(startDate, 'Saturday'));
		system.assertEquals(startDate.addDays(5), DateUtility.getDateOfNextNamedDay(startDate, 'Sunday'));
		system.assertEquals(startDate.addDays(6), DateUtility.getDateOfNextNamedDay(startDate, 'Monday'));
		system.assertEquals(startDate.addDays(7), DateUtility.getDateOfNextNamedDay(startDate, 'Tuesday'));
		
		startDate = date.valueOf('2012-12-31'); //Testing over end of year
		system.assertEquals(startDate.addDays(1), DateUtility.getDateOfNextNamedDay(startDate, 'Tuesday'));
		
		startDate = null;
		system.assertEquals(null, DateUtility.getDateOfNextNamedDay(startDate, 'Tuesday'));
	}
	
	static testMethod void testDateOfPreviousNamedDay(){
		date startDate = date.valueOf('2012-03-01'); //Testing over a leap year
		system.assertEquals(startDate.addDays(-1), DateUtility.getDateOfPreviousNamedDay(startDate, 'Wednesday'));
		system.assertEquals(startDate.addDays(-2), DateUtility.getDateOfPreviousNamedDay(startDate, 'Tuesday'));
		system.assertEquals(startDate.addDays(-3), DateUtility.getDateOfPreviousNamedDay(startDate, 'Monday'));
		system.assertEquals(startDate.addDays(-4), DateUtility.getDateOfPreviousNamedDay(startDate, 'Sunday'));
		system.assertEquals(startDate.addDays(-5), DateUtility.getDateOfPreviousNamedDay(startDate, 'Saturday'));
		system.assertEquals(startDate.addDays(-6), DateUtility.getDateOfPreviousNamedDay(startDate, 'Friday'));
		system.assertEquals(startDate.addDays(-7), DateUtility.getDateOfPreviousNamedDay(startDate, 'Thursday'));
		
		startDate = date.valueOf('2009-01-01'); //Testing over end of year
		system.assertEquals(startDate.addDays(-7), DateUtility.getDateOfPreviousNamedDay(startDate, 'Thursday'));
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 12/06/2015
    Version - 1.0
    Function - test that current day is returned when custom settings cut-off time is after NOW()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testGetDateOfNextNamedDayWithTimePositive(){
		Time tBase = Datetime.now().addMinutes(10).time();
		insert new General__c(Name = Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME, Value__c = tBase.hour()+Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME_SPLIT+tBase.minute());
		Date thursday = Date.newInstance(2015, 6, 23);

		Test.startTest();
		System.assertEquals(thursday, DateUtility.getDateOfNextNamedDay(thursday, 'Tuesday'));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 12/06/2015
    Version - 1.0
    Function - test that current day + 7 days is returned when custom settings cut-off time is before NOW()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testGetDateOfNextNamedDayWithTimeNegative(){
		Time tBase = Datetime.now().addMinutes(-10).time();
		insert new General__c(Name = Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME, Value__c = tBase.hour()+Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME_SPLIT+tBase.minute());
		Date thursday = Date.newInstance(2015, 6, 23);

		Test.startTest();
		System.assertEquals(thursday.addDays(7), DateUtility.getDateOfNextNamedDay(thursday, 'Tuesday'));
		Test.stopTest();


	}
}