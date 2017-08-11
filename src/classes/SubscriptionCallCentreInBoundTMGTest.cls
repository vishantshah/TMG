/**
* @author Wiktor Czykin
* @date 17/05/2016
* @description Test class for SubscriptionCallCentreInBoundTMG
                Restarted history tracking as main class was repurposed so test class is rewritten.
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class SubscriptionCallCentreInBoundTMGTest{

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Basic assertion of object initialization
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testConstructor(){
        Test.startTest();
            SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
            System.assert(!scci.lstProductTypes.isEmpty());
            System.assertNotEquals(null, scci.offerSelection);
            System.assertEquals(scci.offerSelection.sSelectedProductType,  Constants.PRODUCT_PREMIUM);
            System.assert(!scci.bProductSelected);
            System.assert(!scci.offerSelection.bIsActive);
            System.assertEquals(Constants.SUB_ORDER_METHOD_INBOUND, scci.offerSelection.sOrderMethod);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test product selection method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testProductSelection(){
        Test.startTest();
            SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
            System.assert(!scci.bProductSelected);
            scci.selectProduct();
            System.assert(scci.bProductSelected);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test return self method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSelf(){
        Test.startTest();
            SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
            System.assertEquals(scci, scci.getSelf());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test validation method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testValidateRequest(){
        Test.startTest();
            SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
            scci.validateRequestParameters();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_tcode_no_poc_issue_error));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Product_was_not_selected));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test failure because of validation on redirection
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOfferSelectionFailure(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        Test.startTest();
            System.assertEquals(null, scci.processOfferSelection());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test failure because of wrong decimal
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOfferSelectionException(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_ADHOCPRICE;
        scci.offerSelection.sTcode = td.lstTCodeManagement[0].Name;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        scci.offerSelection.sDiscountPrice = 'abc';
        Test.startTest();
            System.assertEquals(null, scci.processOfferSelection());
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_OAP_redirection_issue));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test OpenOffer offer parameters are passed correctly
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOpenOfferSelection(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_OPENOFFER;
        scci.offerSelection.sTcode = td.lstTCodeManagement[0].Name;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        scci.offerSelection.sSelectedProductType = 'sProductType';
        scci.offerSelection.sTsNumber = 'ts123456';
        scci.offerSelection.sGuid = '123324123';
        scci.offerSelection.sSurname = 'tester';
        scci.offerSelection.sPostCode = 'end of the world';

        Test.startTest();
            PageReference pr = scci.processOfferSelection();
            System.assertNotEquals(null, pr, 'Reference returned as null where should not be.');
            Map<String, String> mapParams = pr.getParameters();
            System.assertEquals(UserInfo.getUserId(), mapParams.get(OapSubscriptionTMG.PARAM_AGENT_USERID));
            System.assertEquals(td.lstTCodeManagement[0].Name, mapParams.get(OapSubscriptionTMG.PARAM_TCODE));
            System.assertEquals(td.lstZproducts[0].Id, mapParams.get(OapSubscriptionTMG.PARAM_PRODUCTID));
            System.assertEquals(scci.offerSelection.sSelectedProductType, mapParams.get(OapSubscriptionTMG.PARAM_SELECTED_PRODUCT));
            System.assertEquals(Constants.AGENT_TMG, mapParams.get(OapSubscriptionTMG.PARAM_AGENCYID));
            System.assertEquals(Constants.DIRECTION_INBOUND, mapParams.get(OapSubscriptionTMG.PARAM_ORDER_METHOD));
            System.assertEquals(scci.offerSelection.sTsNumber, mapParams.get(OapSubscriptionTMG.PARAM_TSNUMBER));
            System.assertEquals(scci.offerSelection.sSurname, mapParams.get(OapSubscriptionTMG.PARAM_SURNAME));
            System.assertEquals(scci.offerSelection.sPostCode, mapParams.get(OapSubscriptionTMG.PARAM_POSTCODE));
            System.assertEquals(scci.offerSelection.sGuid, mapParams.get(OapSubscriptionTMG.PARAM_GUID));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test AdHoc offer parameters are passed correctly
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAdHocPriceSelection(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_ADHOCPRICE;
        scci.offerSelection.sTcode = td.lstTCodeManagement[0].Name;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        scci.offerSelection.sDiscountPrice = '1.50';
        Test.startTest();
            PageReference pr = scci.processOfferSelection();
            System.assertNotEquals(null, pr, 'Reference returned as null where should not be.');
            Map<String, String> mapParams = pr.getParameters();
            System.assertEquals(td.lstTCodeManagement[0].Name, mapParams.get(OapSubscriptionTMG.PARAM_TCODE));
            System.assertEquals(td.lstZproducts[0].Id, mapParams.get(OapSubscriptionTMG.PARAM_PRODUCTID));
            System.assertEquals(scci.offerSelection.sDiscountPrice, mapParams.get(OapSubscriptionTMG.PARAM_FORCED_PRICE));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test Promotion offer parameters are passed correctly
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPromotionSelection(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_PROMOTION;
        scci.offerSelection.sTcodeId = td.lstTCodeManagement[0].Id;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        Test.startTest();
            PageReference pr = scci.processOfferSelection();
            System.assertNotEquals(null, pr, 'Reference returned as null where should not be.');
            Map<String, String> mapParams = pr.getParameters();
            System.assertEquals(td.lstTCodeManagement[0].Name, mapParams.get(OapSubscriptionTMG.PARAM_TCODE));
            System.assertEquals(td.lstZproducts[0].Id, mapParams.get(OapSubscriptionTMG.PARAM_PRODUCTID));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test POC offer parameters are passed correctly
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPOCSelection(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_POC;
        scci.offerSelection.sTcode = td.lstTCodeManagement[0].Name;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        scci.offerSelection.sPocId = 'pcic123';
        Test.startTest();
            PageReference pr = scci.processOfferSelection();
            System.assertNotEquals(null, pr, 'Reference returned as null where should not be.');
            Map<String, String> mapParams = pr.getParameters();
            System.assertEquals(null, mapParams.get(OapSubscriptionTMG.PARAM_TCODE));
            System.assertEquals(td.lstZproducts[0].Id, mapParams.get(OapSubscriptionTMG.PARAM_PRODUCTID));
            System.assertEquals(scci.offerSelection.sPocId, mapParams.get(OapSubscriptionTMG.PARAM_POCID));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test MGM offer parameters are passed correctly
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testMgmSelection(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();
        td.createIndividualSubscribers();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_MGM;
        scci.offerSelection.sTcode = td.lstTCodeManagement[0].Name;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        scci.offerSelection.mgmGiverId = td.lstIndividualSubscribers[0].Id;
        scci.offerSelection.dForcedPrice = 1.50;
        Test.startTest();
            PageReference pr = scci.processOfferSelection();
            System.assertNotEquals(null, pr, 'Reference returned as null where should not be.');
            Map<String, String> mapParams = pr.getParameters();
            System.assertEquals(td.lstTCodeManagement[0].Name, mapParams.get(OapSubscriptionTMG.PARAM_TCODE));
            System.assertEquals(td.lstZproducts[0].Id, mapParams.get(OapSubscriptionTMG.PARAM_PRODUCTID));
            System.assertEquals(scci.offerSelection.dForcedPrice +'', mapParams.get(OapSubscriptionTMG.PARAM_FORCED_PRICE));
            System.assertEquals(scci.offerSelection.mgmGiverId, mapParams.get(OapSubscriptionTMG.PARAM_MGM_GIVERID));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test Staff offer parameters are passed correctly
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testStaffSelection(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        scci.offerSelection.sSelectedOffer = Constants.OFFER_STAFF;
        scci.offerSelection.sTcode = td.lstTCodeManagement[0].Name;
        scci.offerSelection.productId = td.lstZproducts[0].Id;
        scci.offerSelection.sStaffName = 'staff123';
        Test.startTest();
            PageReference pr = scci.processOfferSelection();
            System.assertNotEquals(null, pr, 'Reference returned as null where should not be.');
            Map<String, String> mapParams = pr.getParameters();
            System.assertEquals(td.lstTCodeManagement[0].Name, mapParams.get(OapSubscriptionTMG.PARAM_TCODE));
            System.assertEquals(scci.offerSelection.sStaffName, mapParams.get(OapSubscriptionTMG.PARAM_STAFF_NAME));
        Test.stopTest();
    }
}
