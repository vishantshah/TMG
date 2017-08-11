/**
* Author: Wiktor Czykin
* Date: 17/05/2016
* Description: Simple test for OfferSelectionData
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest
private class OfferSelectionDataTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/05/2016
    Version - 1.0
    Function - Test that nothing is set by default, simple POJO
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testValues(){
        OfferSelectionData osd = new OfferSelectionData();
        System.assertEquals(null, osd.sSelectedProductType);
        System.assertEquals(null, osd.sSelectedOffer);
        System.assertEquals(null, osd.sTcode);
        System.assertEquals(null, osd.sTcodeId);
        System.assertEquals(null, osd.dForcedPrice);
        System.assertEquals(null, osd.pocSfdcId);
        System.assertEquals(null, osd.sPocId);
        System.assertEquals(null, osd.mgmGiverId);
        System.assertEquals(null, osd.sMgmGiverCode);
        System.assertEquals(null, osd.agentUserId);
        System.assertEquals(null, osd.sStaffName);
        System.assertEquals(null, osd.productId);
        System.assertEquals(null, osd.selectedAccountId);
        System.assertEquals(null, osd.sOrderMethod);
        System.assertEquals(null, osd.sTsNumber);
        System.assertEquals(null, osd.bIsActive);
        System.assertEquals(null, osd.sGuid);
        System.assertEquals(null, osd.sSurname);
        System.assertEquals(null, osd.sPostCode);
        System.assertEquals(null, osd.sDiscountPrice);
    }
}
