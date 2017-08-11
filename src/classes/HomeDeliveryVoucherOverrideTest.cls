/**
* Author:       Wiktor Czykin
* Date:         27/07/2017
* Description:  test class for HomeDeliveryVoucherOverride
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest
private class HomeDeliveryVoucherOverrideTest {

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        27/07/2017
    Description test redirect to record type selection where no RecordType is there in get request
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testRedirectToRecordTypeSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();

        Test.startTest();
            PageReference pr = Page.HomeDeliveryVoucherOverride;
            pr.getParameters().put('anything', 'some');
            Test.setCurrentPage(pr);
            HomeDeliveryVoucherOverride hdv = new HomeDeliveryVoucherOverride(new ApexPages.StandardController(new Home_Delivery_Voucher__c()));
            PageReference prResult = hdv.redirect();
            System.assert(prResult.getUrl().contains(HomeDeliveryVoucherOverride.PAGE_RECORDTYPESELECT));
            System.assert(prResult.getParameters().get(HomeDeliveryVoucherOverride.PARAM_SAVENEWURL).contains('anything'));
        Test.stopTest(); 
    } 

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        27/07/2017
    Description test redirect to edit page after record type is selected
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testRedirectAfterRecordTypeSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        Home_Delivery_Fields_Mapping__c hdf = new Home_Delivery_Fields_Mapping__c(Name = 'PersonEmail', Home_Delivery_Field_Id__c='someid');
        insert hdf;

        Test.startTest();
            PageReference pr = Page.HomeDeliveryVoucherOverride;
            Id recTypeId = RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName());
            pr.getParameters().put(HomeDeliveryVoucherOverride.PARAM_RECORDTYPE, recTypeId);
            pr.getParameters().put('someParamThatIsAccountId', td.lstIndividualSubscribers[0].Id);
            Test.setCurrentPage(pr);
            HomeDeliveryVoucherOverride hdv = new HomeDeliveryVoucherOverride(new ApexPages.StandardController(new Home_Delivery_Voucher__c()));
            PageReference prResult = hdv.redirect();
            System.assert(!prResult.getUrl().contains(HomeDeliveryVoucherOverride.PAGE_RECORDTYPESELECT));
        Test.stopTest(); 
    }

}