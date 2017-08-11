/**
* @author Unknown
* @date Unknown
* @description Utility class
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin    1.1        12/01/2016  //removed unused code, added some comments
Wiktor Czykin    1.2        30/08/2016  //added new version of getDeliveryOptions()
Vishant Shah     1.3        04/01/2017  //added getStartDates and removed unnecessary methods
                                        //also tidied getDateAsString method
**/
public class UtilitySelectOptionsSubscriptions {

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - Prepare custom select options list for delivery types
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<SelectOption> getDeliveryOptions(Boolean includeHND) {
        List<SelectOption> options = new List<SelectOption>{new SelectOption(Constants.DELIVERYTYPE_OTC, Constants.DELIVERYTYPE_OTC)};
        if (includeHND){
            options.add(new SelectOption(Constants.DELIVERYTYPE_HND, Constants.DELIVERYTYPE_HND));
        }
        return options;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/08/2016
    Version - 1.0
    Function - get delivery option based on ZProduct Voucher_Delivery_Type__c field value
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<SelectOption> getDeliveryOptions(String sProductVouncherDelivery){
        if(String.isBlank(sProductVouncherDelivery) || sProductVouncherDelivery == Constants.DELIVERYTYPE_BOTH){
            return new List<SelectOption>{  new SelectOption(Constants.DELIVERYTYPE_OTC, Constants.DELIVERYTYPE_OTC),
                                            new SelectOption(Constants.DELIVERYTYPE_HND, Constants.DELIVERYTYPE_HND)
            };
        }else if(sProductVouncherDelivery == Constants.DELIVERYTYPE_OTC){
            return new List<SelectOption>{  new SelectOption(Constants.DELIVERYTYPE_OTC, Constants.DELIVERYTYPE_OTC)};
        }else if(sProductVouncherDelivery == Constants.DELIVERYTYPE_HND){
            return new List<SelectOption>{  new SelectOption(Constants.DELIVERYTYPE_HND, Constants.DELIVERYTYPE_HND)};
        }
        return new List<SelectOption>();
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - Prepare custom select options list based on Account salutation picklist
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<SelectOption> getPersonTitleValues() {
        List<SelectOption> options = new List<SelectOption>();
           List<Schema.PicklistEntry> ple = Account.Salutation.getDescribe().getPicklistValues();
           for(Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - Returns custom select options list for offer options. Used eg. on OAPSubscritptionTMG page
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<SelectOption> getOfferOptions() {
           return new List<SelectOption>{
                                        new SelectOption('None','None'),
                                        new SelectOption('Email','Email'),
                                        new SelectOption('Coupon','Coupon'),
                                        new SelectOption('Both','Both')
        };
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - Returns custom select options list for offer options. Used eg. on OAPSubscritptionTMG page
    #############Change Log#############
    Modified by     Version     Change Date
    Vishant Shah    1.3         tidied up method naming conventions.
    ****************************************************************************************/
    public static String getDateAsString(Date thisDate){
        Datetime tempDate = datetime.valueOfGmt(String.valueOf(thisDate) + ' 00:00:00');
        return tempDate.format('EEEE, d MMMM yyyy');
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 04/01/2017
    Version - 1.0
    Function - Returns custom select options list for offer options on OAPSubscritptionTMG.  
               Cleaned other methods
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public static List<SelectOption> getStartDates(Integer numberOfWeeks, Integer leadDays){
         
        Integer addDays            = 7;
        List<SelectOption> options = new List<SelectOption>();
        Date firstStartDate        = getFirstStartDate(leadDays, 5);
        Date nextStartDate;
 
        options.add(new SelectOption('', ''));
        options.add(new SelectOption(firstStartDate.format(), getDateAsString(firstStartDate)));

        for (Integer i = 1; i <= numberOfWeeks; i++){
            nextStartDate = firstStartDate.addDays(addDays);
            options.add(new SelectOption(nextStartDate.format(), getDateAsString(nextStartDate) ));
            addDays +=7;
        }

        return options;
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 04/01/2017
    Version - 1.0
    Function - method to return the first start date of subscription
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public static Date getFirstStartDate(Integer leadDays, Integer daysToAdd){

        Integer daysFromStartOfWeek = date.today().toStartofWeek().daysBetween(date.today());
        Date closestSaturday        = DateUtility.getDateOfNextNamedDay(date.today(), 'Saturday');
        Date firstStartDate;

        if (daysFromStartOfWeek > 4){
            leadDays += 7;
        }

        return closestSaturday.addDays(leadDays);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - 
    Version - 1.0
    Function - method to return the first start date of subscription
    #############Change Log#############
    Modified by     Version     Change Date 
    Vishant Shah    1.1         amended to call the overridden method above and change parameter from 
                                version to daysToAdd
    ****************************************************************************************/
    public static Date getFirstStartDate(Integer daysToAdd){
        return getFirstStartDate(9, daysToAdd);
    }
}