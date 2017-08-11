/**
* @author Wiktor Czykin
* @date 06/05/2016
* @description Test class for ProductSwitchController
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin	1.1			08/11/2016 //added test coverage for new constructor
**/
@isTest
private class ProductSwitchControllerTest {

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 08/11/2016
	Version - 1.0
	Function - simple method to init params for oap page 
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static PageReference prepareOAPReference(TestDataUtility tdu){
		PageReference pr = Page.OapSubscriptionTMG;
		Map<String, String> mapParams = pr.getParameters();
		mapParams.put(OapSubscriptionTMG.PARAM_ORDER_METHOD, Constants.PRODUCT_PREMIUM);
		mapParams.put(OapSubscriptionTMG.PARAM_TCODE, tdu.lstTCodeManagement[0].Name);
		mapParams.put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
		mapParams.put(OapSubscriptionTMG.PARAM_PRODUCTID, tdu.lstTCodeProducts[0].Product__c);
		return pr;
	} 

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/05/2016
	Version - 1.0
	Function - test failure when not valid parameters are passed to constructor
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testMethodtestConstructorFailure(){
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createTCodeProducts();
		Test.startTest();
			try{
				ProductSwitchController psc = new ProductSwitchController(null, null, null, null);
				System.assert(false, 'Exception not thrown where should be.');
			}catch(TelegraphApplicationException e){
				System.assert(e.getMessage().contains(Label.Product_Switch_Wrong_parameters_for_init));
			}
		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/05/2016
	Version - 1.1
	Function - test positive flow where match is found for the passed in parameters
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin 	1.1			08/11/2016 //added assertion to check if incentives were set
	****************************************************************************************/
	private static testMethod void testConstructorPositiveMatchFound(){
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createTCodeProductIncentives();
		for(zqu__ZProduct__c prod : tdu.lstZproducts){
			prod.Print_Product__c = true;
		}
		update tdu.lstZproducts;
		
		Test.setCurrentPage(prepareOAPReference(tdu));
		OapSubscriptionTMG pss = new OapSubscriptionTMG();

		Test.startTest();
			ProductSwitchController psc = new ProductSwitchController(pss, pss.productId, pss.currentCampaign.Id, null);
		Test.stopTest();

		System.assertEquals(pss.productId, psc.productId);
		System.assertEquals(pss.tCode, psc.sTCodeName);
		System.assertEquals(true, psc.bPrintProducts);
		System.assertEquals(pss.currentCampaign.Id, psc.tCodeId);
		System.assert(!psc.bShowOtherProducts);
		System.assert(psc.bProductTCodeMatch, 'Passed in product not found in tcode where it should be.');
		System.assert(!psc.lstProductsForTCode.isEmpty());
		System.assertNotEquals(null, psc.selectedProduct);
		for(TCodeProductWrapper tpw : psc.lstProductsForTCode){
			String.isNotBlank(tpw.incentives);
		}
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 08/11/2016
	Version - 1.0
	Function - new method to check that incentives are NOT set if they are not valid for renewal
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testConstructorNoIncentivesBecauseNotRenewalOnes(){
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createTCodeProductIncentives();
		for(zqu__ZProduct__c prod : tdu.lstZproducts){
			prod.Print_Product__c = true;
		}
		update tdu.lstZproducts;
		Test.setCurrentPage(prepareOAPReference(tdu));
		OapSubscriptionTMG pss = new OapSubscriptionTMG();

		Test.startTest();
			ProductSwitchController psc = new ProductSwitchController(pss, pss.productId, pss.currentCampaign.Id, null, true);
		Test.stopTest();

		System.assertEquals(pss.productId, psc.productId);
		System.assertEquals(pss.tCode, psc.sTCodeName);
		System.assertEquals(true, psc.bPrintProducts);
		System.assertEquals(pss.currentCampaign.Id, psc.tCodeId);
		System.assert(!psc.bShowOtherProducts);
		System.assert(psc.bProductTCodeMatch, 'Passed in product not found in tcode where it should be.');
		System.assert(!psc.lstProductsForTCode.isEmpty());
		System.assertNotEquals(null, psc.selectedProduct);
		for(TCodeProductWrapper tpw : psc.lstProductsForTCode){
			String.isBlank(tpw.incentives);
		}
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/05/2016
	Version - 1.0
	Function - test positive flow where product match is not found for tcode products
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testConstructorPositiveNoMatchFound(){
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createTCodeProducts();
		for(zqu__ZProduct__c prod : tdu.lstZproducts){
			prod.Print_Product__c = true;
		}
		update tdu.lstZproducts;

		PageReference pr = prepareOAPReference(tdu);
		pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, tdu.lstTCodeProducts[1].Product__c);
		Test.setCurrentPage(pr);
		OapSubscriptionTMG pss = new OapSubscriptionTMG();

		Test.startTest();
			ProductSwitchController psc = new ProductSwitchController(pss, pss.productId, pss.currentCampaign.Id, true);
		Test.stopTest();

		System.assertEquals(pss.productId, psc.productId);
		System.assertEquals(pss.tCode, psc.sTCodeName);
		System.assertEquals(true, psc.bPrintProducts);
		System.assertEquals(pss.currentCampaign.Id, psc.tCodeId);
		System.assert(psc.bShowOtherProducts);
		System.assert(!psc.bProductTCodeMatch, 'Passed in product found in tcode where it should not be.');
		System.assert(!psc.lstProductsForTCode.isEmpty());
		System.assertEquals(null, psc.selectedProduct);
		System.assert(!ApexPages.getMessages().isEmpty());
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/05/2016
	Version - 1.0
	Function - test negative flow where product match is not found and there are no products on tcode to fix the mismatch
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testConstructorNegativeNoMatchFoundNoProductsToReplace(){
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createTCodeProducts();
		delete tdu.lstZproducts;

		PageReference pr = prepareOAPReference(tdu);
		pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, tdu.lstTCodeProducts[1].Product__c);
		Test.setCurrentPage(pr);
		OapSubscriptionTMG pss = new OapSubscriptionTMG();

		Test.startTest();
			ProductSwitchController psc = new ProductSwitchController(pss, pss.productId, pss.currentCampaign.Id, true);
		Test.stopTest();

		System.assertEquals(pss.productId, psc.productId);
		System.assertEquals(pss.tCode, psc.sTCodeName);
		System.assertEquals(true, psc.bPrintProducts);
		System.assertEquals(pss.currentCampaign.Id, psc.tCodeId);
		System.assert(!psc.bShowOtherProducts);
        System.assert(psc.bHideButtonAndSection);
		System.assert(!psc.bProductTCodeMatch, 'Passed in product found in tcode where it should not be.');
		System.assert(psc.lstProductsForTCode.isEmpty());
		System.assertEquals(null, psc.selectedProduct);
		System.assert(!ApexPages.getMessages().isEmpty());
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/05/2016
	Version - 1.0
	Function - test positive flow - match found and then change to product selected
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testConstructorPositiveChangeProductAndShowOther(){
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createTCodeProducts();
		for(zqu__ZProduct__c prod : tdu.lstZproducts){
			prod.Print_Product__c = true;
		}
		update tdu.lstZproducts;
		tdu.lstTCodeProducts[1].TCodeManagement__c = tdu.lstTCodeManagement[0].Id;
		update tdu.lstTCodeProducts;

		Test.setCurrentPage(prepareOAPReference(tdu));
		OapSubscriptionTMG pss = new OapSubscriptionTMG();

		Test.startTest();
			ProductSwitchController psc = new ProductSwitchController(pss, pss.productId, pss.currentCampaign.Id, null);
			System.assertEquals(pss.productId, psc.productId);
			System.assertEquals(pss.tCode, psc.sTCodeName);
			System.assertEquals(true, psc.bPrintProducts);
			System.assertEquals(pss.currentCampaign.Id, psc.tCodeId);
			System.assert(!psc.bShowOtherProducts);
			System.assert(psc.bProductTCodeMatch, 'Passed in product not found in tcode where it should be.');
			System.assert(!psc.lstProductsForTCode.isEmpty());
			System.assertNotEquals(null, psc.selectedProduct);
			psc.showOtherProducts();
			System.assert(psc.bShowOtherProducts);
			List<TCodeProductWrapper> lstProducts = psc.getProducts();
			System.assertEquals(1, lstProducts.size());
			psc.productId = lstProducts[0].productId;
			psc.changeProduct();
			System.assertEquals(psc.productId, pss.productId);
		Test.stopTest();
	}
}
