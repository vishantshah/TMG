/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         27/05/2015  //modified testGetCreatableFieldsSOQL()
Wiktor Czykin	1.2			25/02/2016	//removed testGetCreatableFieldsSOQL()
**/
@isTest
private class UtilitiesTest {
	
	private static testMethod void testGetOpportunityStage() {
		OpportunityStage oppStage = Utilities.getOpportunityStage(90);
		system.assertEquals('Sales - (90%) Agreed, Awaiting IO', oppStage.MasterLabel, 'The master label returned was not \'oppStage.MasterLabel\'');
	}
	
	private static testMethod void testGetCurrencySymbol() {
		String currencyISO = 'GBP';
		String currencySymbol = Utilities.getCurrencySymbol(currencyISO);
		system.assertEquals('£', currencySymbol, 'currency symbol for ISO GBP was not £');
	}
	
	// based on 4-4-5 week calender
	private static testMethod void testGetFiscalMonthFromFiscalWeek() {
		Integer fiscalWeek = 1;
		Integer fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		Integer expectedFiscalMonth = 1;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		fiscalWeek = 5;
		fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		expectedFiscalMonth = 2;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		fiscalWeek = 8;
		fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		expectedFiscalMonth = 2;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		fiscalWeek = 9;
		fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		expectedFiscalMonth = 3;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		fiscalWeek = 12;
		fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		expectedFiscalMonth = 3;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		fiscalWeek = 13;
		fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		expectedFiscalMonth = 3;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		fiscalWeek = 14;
		fiscalMonth = Utilities.getFiscalMonth(fiscalWeek);
		expectedFiscalMonth = 4;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
	}
	
	private static testMethod void testGetNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth() {
		Integer fiscalMonth = 1;
		Integer numberOfFiscalWeeks = Utilities.getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		Integer expectedNumberOfFiscalWeeks = 0;
		system.assertEquals(expectedNumberOfFiscalWeeks, numberOfFiscalWeeks);
		
		fiscalMonth = 2;
		numberOfFiscalWeeks = Utilities.getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		expectedNumberOfFiscalWeeks = 4;
		system.assertEquals(expectedNumberOfFiscalWeeks, numberOfFiscalWeeks);
		
		fiscalMonth = 3;
		numberOfFiscalWeeks = Utilities.getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		expectedNumberOfFiscalWeeks = 8;
		system.assertEquals(expectedNumberOfFiscalWeeks, numberOfFiscalWeeks);
		
		fiscalMonth = 4;
		numberOfFiscalWeeks = Utilities.getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		expectedNumberOfFiscalWeeks = 13;
		system.assertEquals(expectedNumberOfFiscalWeeks, numberOfFiscalWeeks);
		
		fiscalMonth = 5;
		numberOfFiscalWeeks = Utilities.getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		expectedNumberOfFiscalWeeks = 17;
		system.assertEquals(expectedNumberOfFiscalWeeks, numberOfFiscalWeeks);
	}
	
	private static testMethod void testGetFirstAndLastDayOfFiscalMonth() {
		Integer fiscalMonth = 1;
		Integer fiscalYear = 2013;
		Date firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		Date expectedFirstDayOfFiscalMonth = Date.newInstance(2012, 12, 31);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		Date lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		Date expectedLastDayOfFiscalMonth = Date.newInstance(2013, 1, 27);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 2;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 1, 28);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 2, 24);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 3;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 2, 25);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 3, 31);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 4;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 4, 1);	// 5 weeks
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 4, 28);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 5;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 4, 29);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 5, 26);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 6;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 5, 27);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 6, 30);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 7;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 7, 1);	// 5 weeks
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 7, 28);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		// N.B gap in testing fiscal months
		
		fiscalMonth = 10;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 9, 30);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 10, 27);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 11;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 10, 28);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 11, 24);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 12;
		fiscalYear = 2013;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 11, 25);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2013, 12, 29);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
		
		fiscalMonth = 1;
		fiscalYear = 2014;
		firstDayOfFiscalMonth = Utilities.getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedFirstDayOfFiscalMonth = Date.newInstance(2013, 12, 30);
		system.assertEquals(expectedFirstDayOfFiscalMonth, firstDayOfFiscalMonth);
		lastDayOfFiscalMonth = Utilities.getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
		expectedLastDayOfFiscalMonth = Date.newInstance(2014, 1, 26);
		system.assertEquals(expectedLastDayOfFiscalMonth, lastDayOfFiscalMonth);
	}
	
	private static testMethod void testGetStartDateOfFiscalYear() {
		Integer fiscalYear = 2012;
		Date startDateOfFiscalYear = Utilities.getStartDateOfFiscalYear(fiscalYear);
		Date expectedStartDateOfFiscalYear = Date.newInstance(2012, 1, 2);
		system.assertEquals(expectedStartDateOfFiscalYear, startDateOfFiscalYear);
		
		fiscalYear = 2013;
		startDateOfFiscalYear = Utilities.getStartDateOfFiscalYear(fiscalYear);
		expectedStartDateOfFiscalYear = Date.newInstance(2012, 12, 31);
		system.assertEquals(expectedStartDateOfFiscalYear, startDateOfFiscalYear);
		
		fiscalYear = 2014;
		startDateOfFiscalYear = Utilities.getStartDateOfFiscalYear(fiscalYear);
		expectedStartDateOfFiscalYear = Date.newInstance(2013, 12, 30);
		system.assertEquals(expectedStartDateOfFiscalYear, startDateOfFiscalYear);
	}
	
	private static testMethod void testPopulateFiscalYearSettingsMap() {
		system.assertEquals(0, Utilities.fiscalYearSettingsMap.size());
		Utilities.populateFiscalYearSettingsMap();
		system.assertEquals(true, Utilities.fiscalYearSettingsMap.size()>0);
	}
	
	private static testMethod void testGetFiscalYear() {
		Date d = Date.newInstance(2013, 11, 15);
		Integer fiscalYear = Utilities.getFiscalYear(d);
		Integer expectedFiscalYear = 2013;
		system.assertEquals(expectedFiscalYear, fiscalYear);
	}
	
	private static testMethod void testGetFiscalWeek() {
		
		Date d = Date.newInstance(2012, 12, 31); // mon, first day of fiscal year 2013
		Integer fiscalWeek = Utilities.getFiscalWeek(d);
		Integer expectedFiscalWeek = 1;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2012, 12, 30); // sun, last day of fiscal year 2012
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 52;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 6); // sun
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 1;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 7); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 2;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 13); // sun
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 2;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 14); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 3;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 20); // sun
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 3;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 21); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 4;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 27); // sun
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 4;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 1, 28); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 5;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 2, 3); // sun
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 5;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 2, 4); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 6;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		// N.B gap in testing fiscal weeks
		
		d = Date.newInstance(2013, 2, 11); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 7;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 2, 18); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 8;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 2, 25); // mon
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 9;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		// N.B gap in testing fiscal weeks
		
		d = Date.newInstance(2013, 12, 29); // sun, last day of fiscal year 2013
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 52;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
		
		d = Date.newInstance(2013, 12, 30); // mon, first day of fiscal year 2014
		fiscalWeek = Utilities.getFiscalWeek(d);
		expectedFiscalWeek = 1;
		system.assertEquals(expectedFiscalWeek, fiscalWeek);
	}
	
	private static testMethod void testGetFiscalMonthFromDate() {
		
		Date d = Date.newInstance(2012, 12, 31); // mon, first day of fiscal year 2013
		Integer fiscalMonth = Utilities.getFiscalMonth(d);
		Integer expectedFiscalMonth = 1;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		d = Date.newInstance(2012, 12, 30); // sun, last day of fiscal year 2012
		fiscalMonth = Utilities.getFiscalMonth(d);
		expectedFiscalMonth = 12;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		d = Date.newInstance(2013, 12, 29); // sun, last day of fiscal year 2013
		fiscalMonth = Utilities.getFiscalMonth(d);
		expectedFiscalMonth = 12;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		d = Date.newInstance(2013, 12, 30); // mon, first day of fiscal year 2014
		fiscalMonth = Utilities.getFiscalMonth(d);
		expectedFiscalMonth = 1;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		d = Date.newInstance(2013, 3, 1);
		fiscalMonth = Utilities.getFiscalMonth(d);
		expectedFiscalMonth = 3;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
		d = Date.newInstance(2013, 3, 31);
		fiscalMonth = Utilities.getFiscalMonth(d);
		expectedFiscalMonth = 3;
		system.assertEquals(expectedFiscalMonth, fiscalMonth);
		
	}
}