/**
* @author Unknown
* @date Unknown
* @description Test class for UtilitySelectOptionsSubscriptions
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin    1.1        12/01/2016  //removed unused code
Wiktor Czykin    1.2        02/09/2016  //added coverage for new getDeliveryOptionsMethod() ->testGetDeliveryOptionsWithString()
Vishant Shah     1.3        04/01/2017  //changed testCreatePreferredStartDates()
**/
@isTest
private class UtilitySelectOptionsSubscriptionsTest {

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test start dates picklist generation
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2016  //added extra line to quickly cover one extra method
    Vishant Shah    1.2         04/01/2017  //changed method call
    ****************************************************************************************/
    private static testMethod void testCreatePreferredStartDates(){
        Test.startTest();
            List<SelectOption> returnOptions = UtilitySelectOptionsSubscriptions.getStartDates(10,9);
            SelectOption so = returnOptions[1];
            String newDate =  so.getvalue();
            Date firstdate = Date.parse(newDate);
            Date newfirstdt = firstdate.toStartofWeek();
            System.assertEquals(newfirstdt.format(),so.getvalue());
            returnOptions = UtilitySelectOptionsSubscriptions.getStartDates(10,9);
            System.assertEquals(12, returnOptions.size());
        Test.stopTest();
    }

    private static testMethod void testGetDeliveryOptions(){
        List<SelectOption> deliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(true);
        System.assertEquals(2,deliveryOptions.size());

        deliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(false);
        System.assertEquals(1,deliveryOptions.size());
    }

    private static testMethod void testGetPersonTitleValues(){
        List<SelectOption> personTitleValues = UtilitySelectOptionsSubscriptions.getPersonTitleValues();
        System.assertEquals(6,personTitleValues.size());
    }

    private static testMethod void testGetDateAsString(){
        Test.startTest();
            List<SelectOption> lst = UtilitySelectOptionsSubscriptions.getOfferOptions();
            System.assertEquals(4, lst.size());
        Test.stopTest();
    }

    private static testMethod void testGetOfferOptions(){
        Date enterDate =  date.newInstance(2010, 10, 25);

        String returnVal = UtilitySelectOptionsSubscriptions.getDateAsString(enterDate);
        System.assertEquals('Monday, 25 October 2010',returnVal);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/09/2016
    Version - 1.0
    Function - test getDeliveryOptions method that is driven by product related delivery options
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetDeliveryOptionsWithString(){
        Test.startTest();
            String s;
            List<SelectOption> deliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(s);
            System.assertEquals(2, deliveryOptions.size());

            deliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(Constants.DELIVERYTYPE_HND);
            System.assertEquals(1, deliveryOptions.size());

            deliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(Constants.DELIVERYTYPE_BOTH);
            System.assertEquals(2, deliveryOptions.size());

            deliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(Constants.DELIVERYTYPE_OTC);
            System.assertEquals(1, deliveryOptions.size());
        Test.stopTest();
    }

}