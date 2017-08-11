/************************************************************************************
Class Name   : DefaultSettings
Author       : Mantas Grigaliunas
Created Date : 16/10/2016
Function     : The class to hold methods that are used to insert the post deployment configurations to org
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date        Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas Grigaliunas    25/10/2016  Added defineNotificationBannerSettings() method
* Vishant Shah          02/11/2016  Added Voucher_Refund_Threshold_Amount__c
* Pawel Chrzanowski     28/11/2016  Added Core Api Custom Settings
* Mantas Grigaliunas    08/12/2016  Added getHolidayVoucherChequeRefundRepiortId()
* Mantas Grigaliunas    10/02/2017  Added MPP_Refund_Email_Template_Name__c field
*************************************************************************************/
public class DefaultSettings {

    private static Configuration__c config = Configuration__c.getInstance();

    public static Configuration__c APPLICATION_CONFIGURATIONS {
        get {
            Configuration__c c = new Configuration__c();
            c.Visualforce_Base_Url__c = getVisualforceBaseUrl();
            c.Voucher_Refund_Threshold_Amount__c = Constants.VOUCHER_REFUND_THRESHOLD_CUSTOM_SETTING_AMOUNT;
            c.Holiday_Voucher_Cheque_Refund_Report_Id__c = getHolidayVoucherChequeRefundReportId(Constants.HOLIDAY_VOUCHER_REFUND_CHEQUE_REPORT_NAME);
            c.MPP_Refund_Email_Template_Name__c = Constants.MPP_REFUND_EMAIL_TEMPLATE_NAME;
			return c;
		}
	}

    public static List<Notification_Banner_Setting__c> NOTIFICATION_BANNER_SETTINGS {
        get {
            return defineNotificationBannerSettings(); 
        }
    }

    public static String CORE_API_APP_ID {
        get {
			return (config.Core_Api_App_Id__c == null && Test.isRunningTest() ? 'app_id' : config.Core_Api_App_Id__c);
        }
    }

    public static String CORE_API_APP_ID_VALUE {
        get {
            return (config.Core_Api_App_Id_Value__c == null && Test.isRunningTest() ? '00000001' : config.Core_Api_App_Id_Value__c);
        }
    }

    public static String CORE_API_APP_KEY {
        get {
            return (config.Core_Api_App_Key__c == null && Test.isRunningTest() ? 'app_key' : config.Core_Api_App_Key__c);
        }
    }

    public static String CORE_API_APP_KEY_VALUE {
        get {
            return (config.Core_Api_App_Key_Value__c == null && Test.isRunningTest() ? '00000000000000000000000000000001' : config.Core_Api_App_Key_Value__c);
        }
    }

    //number of setting records created
    @TestVisible private static final Integer NOTIFICATION_BANNER_SETTINGS_SIZE = 1;

    /************************************************************************************
    Method Name  : getVisualforceBaseUrl
    Created by   : Mantas Grigaliunas
    Date         : 16/10/2016
    Function     : Builds the base visualforce url which is used to access pages that are packaged or using the packaged components
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static String getVisualforceBaseUrl(){
        String instance = [ SELECT InstanceName FROM Organization LIMIT 1 ].InstanceName;
        return String.format(Label.Configuration_Visualforce_Base_Url, new List<String>{instance.toLowerCase()});
    }

    /************************************************************************************
    Method Name  : getHolidayVoucherChequeRefundRepiortId
    Created by   : Mantas Grigaliunas
    Change Date  : 08/12/2016
    Function     : Get id of the report
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static String getHolidayVoucherChequeRefundReportId(String reportName){
        List<Report> reports = new List<Report>([ SELECT Id FROM Report WHERE DeveloperName = :reportName LIMIT 1]);
        if(reports.size() > 0){
            String reportId = reports[0].Id;
            return reportId.substring(0, 15);
        } else {
            return null;
        }
    }

    /************************************************************************************
    Method Name  : defineNotificationBannerSettings
    Created by   : Mantas Grigaliunas
    Change Date  : 24/10/2016
    Function     : Creates the list of Notification Banner Settings custom settings
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private static List<Notification_Banner_Setting__c> defineNotificationBannerSettings(){

        List<Notification_Banner_Setting__c> lstBannerSettings = new List<Notification_Banner_Setting__c>();
        Notification_Banner_Setting__c  accountDuplicationNotification = new Notification_Banner_Setting__c(
            Name = 'Account Duplication Notification',
            Active__c = true,
            Fields__c = 'Duplicate_Of__c,Duplicate_Of__r.Name',
            Message__c = 'This account is duplicate of <a href="/{0}" target="_blank">{1}</a>',
            Object__c = 'Account',
            Severity__c = 'WARNING'
        );
        lstBannerSettings.add(accountDuplicationNotification);
        return lstBannerSettings;
    }
}