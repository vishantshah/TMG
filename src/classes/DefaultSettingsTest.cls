/************************************************************************************
Class Name   : DefaultSettingsTest
Author       : Mantas Grigaliunas
Created Date : 16/10/2016
Function     : DefaultSettings class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer           Date        Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas Grigaliunas  25/10/2016  Added test method for defineNotificationBannerSettings()
* Pawel Chrzanowski   28/11/2016  Added testCoreApiSettings()
*************************************************************************************/
@isTest
private class DefaultSettingsTest {

    /************************************************************************************
    Method Name  : testGetVisualforceBaseUrl
    Author       : Mantas Grigaliunas
    Created Date : 16/10/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void testGetVisualforceBaseUrl(){
        String instance = [ SELECT InstanceName FROM Organization LIMIT 1 ].InstanceName;

        Test.startTest();
        System.assertEquals(String.format(Label.Configuration_Visualforce_Base_Url, new List<String>{instance.toLowerCase()}),
        DefaultSettings.APPLICATION_CONFIGURATIONS.Visualforce_Base_Url__c);
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : testDefineNotificationBannerSettings
    Author       : Mantas Grigaliunas
    Created Date : 24/10/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void testDefineNotificationBannerSettings(){
        Test.startTest();
        System.assertEquals(DefaultSettings.NOTIFICATION_BANNER_SETTINGS_SIZE, DefaultSettings.NOTIFICATION_BANNER_SETTINGS.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 28/11/2016
    Version - 1.0
    Test for Application Configurations Core Api custom setting
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    @isTest static void testCoreApiSettings(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.setApplicationConfigurations();

        System.assertEquals('app_id', DefaultSettings.CORE_API_APP_ID);
        System.assertEquals('00000001', DefaultSettings.CORE_API_APP_ID_VALUE);
        System.assertEquals('app_key', DefaultSettings.CORE_API_APP_KEY);
        System.assertEquals('00000000000000000000000000000001', DefaultSettings.CORE_API_APP_KEY_VALUE);
    }
}