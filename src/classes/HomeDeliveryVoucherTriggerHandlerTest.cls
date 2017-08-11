/**
* @author Wiktor Czykin
* @date 23/06/2017
* @description test class for HomeDeliveryVoucherTriggerHandler
*#############Change Log#############
*Modified by     Change Date
*Wiktor Czykin   12/07/2017 //modified testProductMapping()
**/
@isTest
private class HomeDeliveryVoucherTriggerHandlerTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test population of Offer Name and Description based on custom settings  
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testOfferNameAndDescriptionAssignmentOnInsertUpdate(){
        TestDataUtility td = new TestDataUtility(3);
        Map<String, Home_Delivery_Settings__c> mapSettings = td.createHomeDeliverySettings();

        Test.startTest();
            td.createHomeDeliveryVouchers(null);

            List<Home_Delivery_Voucher__c> lstRefetch = [SELECT Id, Offer_Name__c, Description__c, RecordTypeId, RecordType.Name FROM Home_Delivery_Voucher__c WHERE Id IN :td.lstHomeDeliveryVouchers];
            System.assert(!lstRefetch.isEmpty());
            for(Home_Delivery_Voucher__c hdv : lstRefetch){
                System.assertEquals(mapSettings.get(hdv.RecordType.Name).Offer_Name__c, hdv.Offer_Name__c);
                System.assertEquals(mapSettings.get(hdv.RecordType.Name).Offer_Description__c, hdv.Description__c);
            }
            Id otherRtId = RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName());
            System.assertNotEquals(otherRtId, lstRefetch[0].RecordTypeId);
            for(Home_Delivery_Voucher__c hdv : td.lstHomeDeliveryVouchers){
                hdv.RecordTypeId = otherRtId;
            }
            update td.lstHomeDeliveryVouchers;
        Test.stopTest();
        lstRefetch = [SELECT Id, Offer_Name__c, Description__c, RecordTypeId, RecordType.Name FROM Home_Delivery_Voucher__c WHERE Id IN :td.lstHomeDeliveryVouchers];
        System.assert(!lstRefetch.isEmpty());
        for(Home_Delivery_Voucher__c hdv : lstRefetch){
            System.assertEquals(otherRtId, hdv.RecordTypeId);
            System.assertEquals(mapSettings.get(hdv.RecordType.Name).Offer_Name__c, hdv.Offer_Name__c);
            System.assertEquals(mapSettings.get(hdv.RecordType.Name).Offer_Description__c, hdv.Description__c);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test product prepopulation
    #############Change Log#############
    Modified by     Change Date 
    Wiktor Czykin   12/07/2017  //changed registrant to individual subscriber 
    ****************************************************************************************/
    private static testMethod void testProductMapping(){
        TestDataUtility td = new TestDataUtility(3);
        td.checkHomeDeliveryVouchersDependencies();
        Map<String, Home_Delivery_Settings__c> mapSettings = td.createHomeDeliverySettings();

        for(zqu__ZFeature__c pf : td.lstZFeature){
            pf.Active_Days__c = 'SAT-SUN';
        }
        update td.lstZFeature;

        List<Home_Delivery_Voucher__c> lstHdv = new List<Home_Delivery_Voucher__c>();
        for(Integer i = 0; i<td.iCounter; i++){
            Home_Delivery_Voucher__c hdv = TestDataUtility.newHomeDeliveryVoucher(i, null, td.lstIndividualSubscribers[i]);
            hdv.Delivery_Days__c = 'SAT;SUN';
            lstHdv.add(hdv);
        }

        Test.startTest();
            insert lstHdv;
        Test.stopTest();
        List<Home_Delivery_Voucher__c> lstRefetch = [SELECT Id, Product__c FROM Home_Delivery_Voucher__c WHERE Id IN :lstHdv];
        System.assert(!lstRefetch.isEmpty());
        for(Home_Delivery_Voucher__c hdv : lstRefetch){
           System.assertEquals(td.lstZProducts[0].Id, hdv.Product__c);
        }

    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - check duplicate flag population
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testDuplicateFlag(){
        TestDataUtility td = new TestDataUtility(3);
        td.createHomeDeliveryVouchers(null);
        List<Home_Delivery_Voucher__c> lstCloneSame = new List<Home_Delivery_Voucher__c>();
        List<Home_Delivery_Voucher__c> lstCloneOther = new List<Home_Delivery_Voucher__c>();
        Id otherRtId = RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName());

        for(Home_Delivery_Voucher__c hdv : td.lstHomeDeliveryVouchers){
            lstCloneSame.add(hdv.clone(false, true));
            Home_Delivery_Voucher__c hdo = hdv.clone(false, true);
            hdo.RecordTypeId = otherRtId;
            lstCloneOther.add(hdo);
        }

        List<Home_Delivery_Voucher__c> lstRefetch = [SELECT Id, Is_Duplicate__c FROM Home_Delivery_Voucher__c WHERE Id IN :td.lstHomeDeliveryVouchers];
        for(Home_Delivery_Voucher__c hdv : lstRefetch){
            System.assertEquals(false, hdv.Is_Duplicate__c);
        }
        Test.startTest();
            insert lstCloneSame;
            insert lstCloneOther;
            lstRefetch = [SELECT Id, Is_Duplicate__c FROM Home_Delivery_Voucher__c WHERE Id IN :td.lstHomeDeliveryVouchers];
            for(Home_Delivery_Voucher__c hdv : lstRefetch){
                System.assertEquals(false, hdv.Is_Duplicate__c, 'duplicate flag checked where should not be');
            }
            lstRefetch = [SELECT Id, Is_Duplicate__c FROM Home_Delivery_Voucher__c WHERE Id IN :lstCloneSame];
             for(Home_Delivery_Voucher__c hdv : lstRefetch){
                System.assertEquals(true, hdv.Is_Duplicate__c, 'duplicate flag not checked where should be');
            }
            lstRefetch = [SELECT Id, Is_Duplicate__c FROM Home_Delivery_Voucher__c WHERE Id IN :lstCloneOther];
             for(Home_Delivery_Voucher__c hdv : lstRefetch){
                System.assertEquals(false, hdv.Is_Duplicate__c, 'duplicate flag checked where should not be');
            }
        Test.stopTest();
    }

}