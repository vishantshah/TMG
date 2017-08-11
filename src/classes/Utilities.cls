public class Utilities {
	
/* -----------------------------------------------------------------------------------------------------------------------
   Name:        Utilities.cls
   Description: Utility class for calculating Fiscal Revenue  

   Date        	Version	Author						Summary of Changes 
   -----------	-------	-----------------	------------------------------------------------------------------------------
   11/11/2013		1.0			Chris Yorkston		Intial Release
   25/02/2016		1.1			Wiktor Czykin		Removed getCreatableFieldsSOQL
   18/10/2016 		1.2			Michal Szewczyk	    Added getPickValues()
------------------------------------------------------------------------------------------------------------------------ */
	
	public static final Map<Integer,Integer> numberOfDaysInMonthMap;
	public static final Integer NUMBER_OF_DAYS_PER_WEEK = 7;
	
	// get OpportunityStage record using supplied probabilty
	public static OpportunityStage getOpportunityStage(Integer probability) {
		List<OpportunityStage> opportunityStages = [select Id, MasterLabel from OpportunityStage where IsActive = true and DefaultProbability = :probability];
		OpportunityStage opportunityStage = (opportunityStages!=null&&opportunityStages.size()==1) ? opportunityStages[0] : null;
		return opportunityStage;
	}
  
  	public static String getCurrencySymbol(String iso) {
		String symbol = null; 
		if (iso=='ALL') { symbol='Lek'; }
		else if (iso=='USD') { symbol='$'; }
		else if (iso=='ARS') { symbol='$'; }
		else if (iso=='AWG') { symbol='ƒ'; }
		else if (iso=='AUD') { symbol='$'; }
		else if (iso=='BSD') { symbol='$'; }
		else if (iso=='BBD') { symbol='$'; }
		else if (iso=='BYR') { symbol='p.'; }
		else if (iso=='EUR') { symbol='€'; }
		else if  (iso=='BZD') { symbol='BZ$'; }
		else if (iso=='BMD') { symbol='$'; }
		else if (iso=='BOB') { symbol='$b'; }
		else if (iso=='BAM') { symbol='KM'; }
		else if (iso=='BWP') { symbol='P'; }
		else if (iso=='BRL') { symbol='R$'; }
		else if (iso=='GBP') { symbol='£'; }
		else if (iso=='BND') { symbol='$'; }
		else if (iso=='CAD') { symbol='$'; }
		else if (iso=='KYD') { symbol='$'; }
		else if (iso=='CLP') { symbol='$'; }
		else if (iso=='CNY') { symbol='¥'; }
		else if (iso=='COP') { symbol='$'; }
		else if (iso=='CRC') { symbol='¢'; }
		else if (iso=='HRK') { symbol='kn'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='CZK') { symbol='Kc'; }
		else if (iso=='DKK') { symbol='kr'; }
		else if (iso=='DOP') { symbol='RD$'; }
		else if (iso=='XCD') { symbol='$'; }
		else if (iso=='EGP') { symbol='£'; }
		else if (iso=='SVC') { symbol='$'; }
		else if (iso=='GBP') { symbol='£'; }
		else if (iso=='EEK') { symbol='kr'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='FKP') { symbol='£'; }
		else if (iso=='FJD') { symbol='$'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='GHC') { symbol='¢'; }
		else if (iso=='GIP') { symbol='£'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='GTQ') { symbol='Q'; }
		else if (iso=='GGP') { symbol='£'; }
		else if (iso=='GYD') { symbol='$'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='HNL') { symbol='L'; }
		else if (iso=='HKD') { symbol='$'; }
		else if (iso=='HUF') { symbol='Ft'; }
		else if (iso=='ISK') { symbol='kr'; }
		else if (iso=='IDR') { symbol='Rp'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='IMP') { symbol='£'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='JMD') { symbol='J$'; }
		else if (iso=='JPY') { symbol='¥'; }
		else if (iso=='JEP') { symbol='£'; }
		else if (iso=='LVL') { symbol='Ls'; }
		else if (iso=='LBP') { symbol='£'; }
		else if (iso=='LRD') { symbol='$'; }
		else if (iso=='CHF') { symbol='CHF'; }
		else if (iso=='LTL') { symbol='Lt'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='MYR') { symbol='RM'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='MXN') { symbol='$'; }
		else if (iso=='MZN') { symbol='MT'; }
		else if (iso=='NAD') { symbol='$'; }
		else if (iso=='ANG') { symbol='ƒ'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='NZD') { symbol='$'; }
		else if (iso=='NIO') { symbol='C$'; }
		else if (iso=='NOK') { symbol='kr'; }
		else if (iso=='PAB') { symbol='B/.'; }
		else if (iso=='PYG') { symbol='Gs'; }
		else if (iso=='PEN') { symbol='S/.'; }
		else if (iso=='PHP') { symbol='Php'; }
		else if (iso=='PLN') { symbol='zl'; }
		else if (iso=='RON') { symbol='lei'; }
		else if (iso=='SHP') { symbol='£'; }
		else if (iso=='SGD') { symbol='$'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='SBD') { symbol='$'; }
		else if (iso=='SOS') { symbol='S'; }
		else if (iso=='ZAR') { symbol='R'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='SEK') { symbol='kr'; }
		else if (iso=='CHF') { symbol='CHF'; }
		else if (iso=='SRD') { symbol='$'; }
		else if (iso=='SYP') { symbol='£'; }
		else if (iso=='TWD') { symbol='NT$'; }
		else if (iso=='TTD') { symbol='TT$'; }
		else if (iso=='TRY') { symbol='TL'; }
		else if (iso=='TRL') { symbol='£'; }
		else if (iso=='TVD') { symbol='$'; }
		else if (iso=='GBP') { symbol='£'; }
		else if (iso=='USD') { symbol='$'; }
		else if (iso=='UYU') { symbol='$U'; }
		else if (iso=='EUR') { symbol='€'; }
		else if (iso=='VEF') { symbol='Bs'; }
		else if (iso=='ZWD') { symbol='Z$'; }
		return symbol;
	}
	
	// based on 4-4-5 calender
	public static Integer getFiscalMonth(Integer fiscalWeek) {
		Integer fiscalMonth;
		if (fiscalWeek <= 4) {fiscalMonth=1;}
		else if (fiscalWeek <= 8) {fiscalMonth=2;}
		else if (fiscalWeek <= 13) {fiscalMonth=3;}
		else if (fiscalWeek <= 17) {fiscalMonth=4;}
		else if (fiscalWeek <= 21) {fiscalMonth=5;}
		else if (fiscalWeek <= 26) {fiscalMonth=6;}
		else if (fiscalWeek <= 30) {fiscalMonth=7;}
		else if (fiscalWeek <= 34) {fiscalMonth=8;}
		else if (fiscalWeek <= 39) {fiscalMonth=9;}
		else if (fiscalWeek <= 43) {fiscalMonth=10;}
		else if (fiscalWeek <= 47) {fiscalMonth=11;}
		else if (fiscalWeek <= 52) {fiscalMonth=12;}
		else {fiscalMonth=null;}
		return fiscalMonth;
	}
	
	public static Integer getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(Integer fiscalMonth) {
		Integer numberOfFiscalWeeks;
		if (fiscalMonth==1) {numberOfFiscalWeeks=0;}
		else if (fiscalMonth==2) {numberOfFiscalWeeks=4;}
		else if (fiscalMonth==3) {numberOfFiscalWeeks=8;}
		else if (fiscalMonth==4) {numberOfFiscalWeeks=13;}
		else if (fiscalMonth==5) {numberOfFiscalWeeks=17;}
		else if (fiscalMonth==6) {numberOfFiscalWeeks=21;}
		else if (fiscalMonth==7) {numberOfFiscalWeeks=26;}
		else if (fiscalMonth==8) {numberOfFiscalWeeks=30;}
		else if (fiscalMonth==9) {numberOfFiscalWeeks=34;}
		else if (fiscalMonth==10) {numberOfFiscalWeeks=39;}
		else if (fiscalMonth==11) {numberOfFiscalWeeks=43;}
		else if (fiscalMonth==12) {numberOfFiscalWeeks=47;}
		else {numberOfFiscalWeeks=null;}
		return numberOfFiscalWeeks;
	}
	
	public static Date getFirstDayOfFiscalMonth(Date d) {
		Integer fiscalMonth = getFiscalMonth(d);
		Integer fiscalYear = getFiscalYear(d);
		return getFirstDayOfFiscalMonth(fiscalMonth, fiscalYear);
	}
	
	public static Date getFirstDayOfFiscalMonth(Integer fiscalMonth, Integer fiscalYear) {
		Date firstDayOfFiscalMonth;
		Integer numberOfFiscalWeeks = getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		Date startDateOfFiscalYear = getStartDateOfFiscalYear(fiscalYear);
		firstDayOfFiscalMonth = startDateOfFiscalYear.addDays( numberOfFiscalWeeks * NUMBER_OF_DAYS_PER_WEEK ); // first day of fiscal month
		return firstDayOfFiscalMonth;
	}
	
	public static Date getLastDayOfFiscalMonth(Date d) {
		Integer fiscalMonth = getFiscalMonth(d);
		Integer fiscalYear = getFiscalYear(d);
		return getLastDayOfFiscalMonth(fiscalMonth, fiscalYear);
	}
	
	public static Date getLastDayOfFiscalMonth(Integer fiscalMonth, Integer fiscalYear) {
		Date lastDayOfFiscalMonth;
		Integer numberOfFiscalWeeks = getNumberOfFiscalWeeksElapsedSinceStartOfFiscalMonth(fiscalMonth);
		Date startDateOfFiscalYear = Utilities.getStartDateOfFiscalYear(fiscalYear);
		Integer numberOfWeeksThisFiscalMonth = Constants.listFiscalMonthsNbWeeks[fiscalMonth-1];
		lastDayOfFiscalMonth = startDateOfFiscalYear.addDays( ((numberOfFiscalWeeks + numberOfWeeksThisFiscalMonth) * NUMBER_OF_DAYS_PER_WEEK)-1 ); // last day of fiscal month
		
		return lastDayOfFiscalMonth;
	}
	
	public static Date getStartDateOfFiscalYear(Integer fiscalYear) {
		Date startDateOfFiscalYear;
		
		if (fiscalYearSettingsMap.isEmpty()) populateFiscalYearSettingsMap();
		FiscalYearSettings fys = fiscalYearSettingsMap.get(String.valueOf(fiscalYear));
		
		if (fys!=null) startDateOfFiscalYear = fys.StartDate;
		return startDateOfFiscalYear;
	}
	
	public static Map<String,FiscalYearSettings> fiscalYearSettingsMap = new Map<String,FiscalYearSettings>();
	
	public static void populateFiscalYearSettingsMap() {
		List<FiscalYearSettings> fiscalYearSettings = [select Id, name, startDate, endDate from FiscalYearSettings];
		for (FiscalYearSettings fys :fiscalYearSettings) {
			fiscalYearSettingsMap.put(fys.Name, fys);
		}
		//this.fiscalYearSettingsMap = fiscalYearSettingsMap;
	}
	
	public static Integer getFiscalYear(Date d) {
		Integer fiscalYear;
		
		if (fiscalYearSettingsMap.isEmpty()) populateFiscalYearSettingsMap();
		for (FiscalYearSettings fys :fiscalYearSettingsMap.values()) {
			if (d >= fys.StartDate && d <= fys.EndDate) {
				fiscalYear = Integer.valueOf(fys.Name); break;
			}
		}
		return fiscalYear;
	}
	
	public static Integer getFiscalWeek(Date d) {
		Integer fiscalWeek;
		Date dateToStartOfWeek = d.toStartOfWeek();
		Integer fiscalYear =  Utilities.getFiscalYear(dateToStartOfWeek);
		Date startDateOfFiscalYear = getStartDateOfFiscalYear(fiscalYear);
		Integer numberOfDaysElapsedSinceStartOfYear = startDateOfFiscalYear.daysBetween(dateToStartOfWeek);
		fiscalWeek = (numberOfDaysElapsedSinceStartOfYear / NUMBER_OF_DAYS_PER_WEEK) + 1;
		return fiscalWeek;
	}
	
	public static Integer getFiscalMonth(Date d) {
		Integer fiscalWeek = getFiscalWeek(d);
		return getFiscalMonth(fiscalWeek);
	}
	

	public static List<selectOption> getPickValues(Sobject object_name, String field_name, String first_val) {
      List<selectOption> options = new List<selectOption>();
      if (first_val != null) { 
         options.add(new selectOption(first_val, first_val));
      }
      Schema.sObjectType sobject_type = object_name.getSObjectType(); 
      Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
      Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
      List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues();
      for (Schema.PicklistEntry a : pick_list_values) {
                  
            options.add(new selectOption(a.getValue(), a.getLabel()));
      }
      return options;
}
}